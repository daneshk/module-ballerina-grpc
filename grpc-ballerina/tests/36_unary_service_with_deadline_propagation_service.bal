// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/time;
import ballerina/log;
import ballerina/io;

listener Listener ep36 = new (9126);
const string TEST_DEADLINE_HEADER = "testdeadline";

@ServiceDescriptor {
    descriptor: ROOT_DESCRIPTOR_36,
    descMap: getDescriptorMap36()
}
service "HelloWorld36S1" on ep36 {
    
    remote isolated function call1(ContextString request) returns ContextString|Error {
        log:printInfo("Invoked call1");
        var cancel = isCancelled(request.headers);
        if (cancel is boolean) {
            if (cancel) {
                return error DeadlineExceededError("Exceeded the configured deadline");
            } else {
                HelloWorld36S2Client helloWorldClient = checkpanic new ("http://localhost:9126");
                var deadline = getDeadline(request.headers);
                if (deadline is time:Utc) {
                    string deadlineStringValue = time:utcToString(deadline);
                    request.headers[TEST_DEADLINE_HEADER] = deadlineStringValue;
                    return helloWorldClient->call2Context({content: "WSO2", headers: request.headers});
                } else if (deadline is time:Error) {
                    return error CancelledError(deadline.message());
                } else {
                    return error CancelledError("Deadline is not specified");
                }
            }
        } else {
            return error CancelledError(cancel.message());
        }
    }
}

@ServiceDescriptor {
    descriptor: ROOT_DESCRIPTOR_36,
    descMap: getDescriptorMap36()
}
service "HelloWorld36S2" on ep36 {
    remote isolated function call2(ContextString request) returns ContextString|error {
        log:printInfo("Invoked call2");
        if (request.headers[TEST_DEADLINE_HEADER] != ()) {
            string|string[]? deadlineStringValue = request.headers[TEST_DEADLINE_HEADER];
            if (deadlineStringValue is string) {
                time:Utc currentTime = time:utcNow();
                var deadline = time:utcFromString(deadlineStringValue);
                if (deadline is time:Utc) {
                    [int, decimal] [deadlineSeconds, deadlineSecondFraction] = deadline;
                    [int, decimal] [currentSeconds, currentSecondFraction] = currentTime;
                    io:println(deadline);
                    if currentSeconds < deadlineSeconds {
                        return {content: "Ack", headers: {}};
                    } else if currentSeconds == deadlineSeconds && currentSecondFraction <= deadlineSecondFraction{
                        return {content: "Ack", headers: {}};
                    } else {
                        return error DeadlineExceededError("Exceeded the configured deadline");
                    }
                } else {
                    return error CancelledError(deadline.message());
                }
            }
        }
        return error CancelledError("Test deadline header is not specified");
    }
}

const string ROOT_DESCRIPTOR_36 = "0A3033365F756E6172795F736572766963655F776974685F646561646C696E655F70726F7061676174696F6E2E70726F746F1A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F32550A0E48656C6C6F576F726C643336533112430A0563616C6C31121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C756532550A0E48656C6C6F576F726C643336533212430A0563616C6C32121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C7565620670726F746F33";
isolated function getDescriptorMap36() returns map<string> {
    return {
        "36_unary_service_with_deadline_propagation.proto":"0A3033365F756E6172795F736572766963655F776974685F646561646C696E655F70726F7061676174696F6E2E70726F746F1A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F32550A0E48656C6C6F576F726C643336533112430A0563616C6C31121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C756532550A0E48656C6C6F576F726C643336533212430A0563616C6C32121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C7565620670726F746F33",
        "google/protobuf/wrappers.proto":"0A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F120F676F6F676C652E70726F746F62756622230A0B446F75626C6556616C756512140A0576616C7565180120012801520576616C756522220A0A466C6F617456616C756512140A0576616C7565180120012802520576616C756522220A0A496E74363456616C756512140A0576616C7565180120012803520576616C756522230A0B55496E74363456616C756512140A0576616C7565180120012804520576616C756522220A0A496E74333256616C756512140A0576616C7565180120012805520576616C756522230A0B55496E74333256616C756512140A0576616C756518012001280D520576616C756522210A09426F6F6C56616C756512140A0576616C7565180120012808520576616C756522230A0B537472696E6756616C756512140A0576616C7565180120012809520576616C756522220A0A427974657356616C756512140A0576616C756518012001280C520576616C756542570A13636F6D2E676F6F676C652E70726F746F627566420D577261707065727350726F746F50015A057479706573F80101A20203475042AA021E476F6F676C652E50726F746F6275662E57656C6C4B6E6F776E5479706573620670726F746F33"

    };
}

