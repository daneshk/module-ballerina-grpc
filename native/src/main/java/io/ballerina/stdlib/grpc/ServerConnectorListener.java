/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
package io.ballerina.stdlib.grpc;

import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.grpc.exception.StatusRuntimeException;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.LastHttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_TRACE_PROPERTIES;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_METHOD;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_URL;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_PROTOCOL;
import static io.ballerina.stdlib.grpc.GrpcConstants.GRPC_MESSAGE_KEY;
import static io.ballerina.stdlib.grpc.GrpcConstants.GRPC_STATUS_KEY;
import static io.ballerina.stdlib.grpc.GrpcConstants.MAX_INBOUND_MESSAGE_SIZE;
import static io.ballerina.stdlib.grpc.MessageUtils.statusCodeToHttpCode;

/**
 * gRPC connector listener for Ballerina.
 *
 * @since 0.980.0
 */
public class ServerConnectorListener implements HttpConnectorListener {

    private static final Logger log = LoggerFactory.getLogger(ServerConnectorListener.class);
    private static final String SERVER_CONNECTOR_GRPC = "grpc";
    private static final String GRPC_PROTOCOL = "grpc";

    private final ServicesRegistry servicesRegistry;
    private Map<String, Long> messageSizeMap;

    public ServerConnectorListener(ServicesRegistry servicesRegistry, Map<String, Long> messageSizeMap) {

        this.servicesRegistry = servicesRegistry;
        this.messageSizeMap = messageSizeMap;
    }

    private ExecutorService workerExecutor = Executors.newFixedThreadPool(10,
            new GrpcThreadFactory(new ThreadGroup("grpc-worker"), "grpc-service-worker-thread-pool"));

    @Override
    public void onMessage(HttpCarbonMessage inboundMessage) {
        try {
            InboundMessage request = new InboundMessage(inboundMessage);
            if (!isValid(request)) {
                return;
            }
            OutboundMessage outboundMessage = new OutboundMessage(request);
            // Remove the leading slash of the path and get the fully qualified method name
            CharSequence path = request.getPath();
            String method = path != null ? path.subSequence(1, path.length()).toString() : null;
            deliver(method, request, outboundMessage);
        } catch (RuntimeException ex) {
            try {
                HttpUtil.handleFailure(inboundMessage, ex.getMessage());
            } catch (Exception e) {
                log.error("Cannot handle error using the error handler for: " + e.getMessage(), e);
            }
        }
    }

    @Override
    public void onError(Throwable throwable) {
        log.error("Error in http server connector" + throwable.getMessage(), throwable);
    }

    private void deliver(String method, InboundMessage inboundMessage, OutboundMessage outboundMessage) {
        ServerMethodDefinition methodDefinition = servicesRegistry.lookupMethod(method);
        if (methodDefinition == null) {
            // Use netty http constant.
            handleFailure(inboundMessage.getHttpCarbonMessage(), 404, Status.Code.UNIMPLEMENTED, String.format
                    ("Method not found: %s", method));
            return;
        }

        workerExecutor.execute(() -> {
            ServerCall.ServerStreamListener listener;
            try {
                listener = startCall(inboundMessage, outboundMessage, method);
                ServerInboundStateListener stateListener = new ServerInboundStateListener(
                        messageSizeMap.get(MAX_INBOUND_MESSAGE_SIZE), listener, inboundMessage);
                stateListener.setDecompressor(inboundMessage.getMessageDecompressor());

                HttpContent httpContent = inboundMessage.getHttpCarbonMessage().getHttpContent();
                while (true) {
                    if (httpContent == null) {
                        break;
                    }
                    // Exit the loop at the end of the content
                    if (httpContent instanceof LastHttpContent) {
                        stateListener.inboundDataReceived(httpContent, true);
                        break;
                    } else {
                        stateListener.inboundDataReceived(httpContent, false);
                    }
                    httpContent = inboundMessage.getHttpCarbonMessage().getHttpContent();
                }
            } catch (RuntimeException e) {
                HttpUtil.handleFailure(inboundMessage.getHttpCarbonMessage(), e.getMessage());
            }
        });
    }

    private ServerCall.ServerStreamListener startCall(InboundMessage inboundMessage, OutboundMessage
            outboundMessage, String fullMethodName) {
        // Get method definition of the inboundMessage.
        ServerMethodDefinition methodDefinition = servicesRegistry.lookupMethod(fullMethodName);
        // Create service call instance for the inboundMessage.
        ServerCall call = new ServerCall(inboundMessage, outboundMessage, methodDefinition
                .getMethodDescriptor(), DecompressorRegistry.getDefaultInstance(), CompressorRegistry
                .getDefaultInstance(), messageSizeMap);
        if (ObserveUtils.isObservabilityEnabled()) {
            call.setObserverContext(getObserverContext(fullMethodName, inboundMessage));
        }
        return call.newServerStreamListener(methodDefinition.getServerCallHandler().startCall(call));
    }

    private ObserverContext getObserverContext(String method, InboundMessage inboundMessage) {
        ObserverContext observerContext = new ObserverContext();
        observerContext.setServiceName(SERVER_CONNECTOR_GRPC);
        observerContext.setOperationName(method);

        Map<String, String> httpHeaders = new HashMap<>();
        inboundMessage.getHeaders().forEach(entry -> httpHeaders.put(entry.getKey(), entry.getValue()));
        observerContext.addProperty(PROPERTY_TRACE_PROPERTIES, httpHeaders);
        observerContext.addTag(TAG_KEY_HTTP_METHOD,
                (String) inboundMessage.getProperty(HttpConstants.HTTP_REQUEST_METHOD.getValue()));
        observerContext.addTag(TAG_KEY_PROTOCOL, GRPC_PROTOCOL);
        observerContext.addTag(TAG_KEY_HTTP_URL, inboundMessage.getPath());
        return observerContext;
    }

    private boolean isValid(InboundMessage inboundMessage) {
        HttpHeaders headers = inboundMessage.getHeaders();
        // Validate inboundMessage path.
        CharSequence path = inboundMessage.getPath();
        if (path == null) {
            handleFailure(inboundMessage.getHttpCarbonMessage(), 404, Status.Code.UNIMPLEMENTED, "Expected path is " +
                    "missing");
            return false;
        }
        if (path.charAt(0) != '/') {
            handleFailure(inboundMessage.getHttpCarbonMessage(), 404, Status.Code.UNIMPLEMENTED, String.format
                    ("Expected path to start with /: %s", path));
            return false;
        }
        // Verify that the Content-Type is correct in the inboundMessage.
        CharSequence contentType = headers.get("content-type");
        if (contentType == null) {
            handleFailure(inboundMessage.getHttpCarbonMessage(), 415, Status.Code.INTERNAL, "Content-Type is " +
                    "missing from the request");
            return false;
        }
        String contentTypeString = contentType.toString();
        if (!MessageUtils.isGrpcContentType(contentTypeString)) {
            handleFailure(inboundMessage.getHttpCarbonMessage(), 415, Status.Code.INTERNAL, String.format
                    ("Content-Type '%s' is not supported", contentTypeString));
            return false;
        }
        String method = inboundMessage.getHttpMethod();
        if (!"POST".equals(method)) {
            handleFailure(inboundMessage.getHttpCarbonMessage(), 405, Status.Code.INTERNAL, String.format("Method " +
                    "'%s' is not supported", method));
            return false;
        }
        return true;
    }

    private static void handleFailure(HttpCarbonMessage requestMessage, int status,
                                      Status.Code statusCode, String msg) {
        HttpCarbonMessage responseMessage = HttpUtil.createErrorMessage(msg, status);
        responseMessage.setHeader(GRPC_STATUS_KEY, statusCode.toString());
        responseMessage.setHeader(GRPC_MESSAGE_KEY, msg);
        HttpUtil.sendOutboundResponse(requestMessage, responseMessage);
    }

    private static class ServerInboundStateListener extends InboundMessage.InboundStateListener {

        final ServerCall.ServerStreamListener listener;
        final InboundMessage inboundMessage;

        ServerInboundStateListener(long maxMessageSize, ServerCall.ServerStreamListener listener,
                                   InboundMessage inboundMessage) {
            super(maxMessageSize);
            this.listener = listener;
            this.inboundMessage = inboundMessage;
        }

        @Override
        protected ServerCall.ServerStreamListener listener() {
            return listener;
        }

        @Override
        public void deframerClosed(boolean hasPartialMessage) {
            if (hasPartialMessage) {
                deframeFailed(
                        Status.Code.INTERNAL.toStatus()
                                .withDescription("Encountered end-of-stream mid-frame")
                                .asRuntimeException());
                return;
            }
            listener.halfClosed();
        }

        @Override
        public void deframeFailed(Throwable cause) {
            if (cause instanceof StatusRuntimeException) {
                StatusRuntimeException exp = (StatusRuntimeException) cause;
                handleFailure(inboundMessage.getHttpCarbonMessage(), statusCodeToHttpCode(exp.getStatus().getCode()),
                        exp.getStatus().getCode(), exp.getStatus().getDescription());
                listener.closed(exp.getStatus());
            } else {
                handleFailure(inboundMessage.getHttpCarbonMessage(), 500, Status.Code.INTERNAL, cause.getMessage());
            }
        }

        /**
         * Called in the transport thread to process the content of an inbound DATA frame from the
         * client.
         *
         * @param httpContent Http content.
         * @param endOfStream {@code true} if no more data will be received on the stream.
         */
        void inboundDataReceived(HttpContent httpContent, boolean endOfStream) {
            // Deframe the message. If a failure occurs, deframeFailed will be called.
            deframe(httpContent);
            if (endOfStream) {
                Status status;
                Throwable error = httpContent.getDecoderResult().cause();
                if (error != null) {
                    status = Status.fromCode(Status.Code.CANCELLED).withDescription(error.getMessage());
                    listener.closed(status);
                } else {
                    LastHttpContent lastHttpContent = (LastHttpContent) httpContent;
                    HttpHeaders trailingHeaders = lastHttpContent.trailingHeaders();
                    if (!trailingHeaders.isEmpty()) {
                        status = MessageUtils.statusFromTrailers(trailingHeaders);
                        listener.closed(status);
                    }
                }
                closeDeframer(false);
            }
        }
    }
}
