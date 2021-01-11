// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;

listener Listener ep7 = new (9097);

@ServiceDescriptor {
    descriptor: ROOT_DESCRIPTOR_7,
    descMap: getDescriptorMap7()
}
service "HelloWorld100" on ep7 {
    isolated remote function hello(HelloWorld100StringCaller caller, string name) {
        io:println("name: " + name);
        string message = "Hello " + name;
        Error? err = ();
        if (name == "invalid") {
            err = caller->sendError(error AbortedError("Operation aborted"));
        } else {
            err = caller->send(message);
        }
        if (err is Error) {
            io:println("Error from Connector: " + err.message());
        }
        checkpanic caller->complete();
    }

    isolated remote function testInt(HelloWorld100IntCaller caller, int age) {
        io:println("age: " + age.toString());
        int displayAge = age - 2;
        Error? err = caller->send(displayAge);
        if (err is Error) {
            io:println("Error from Connector: " + err.message());
        } else {
            io:println("display age : " + displayAge.toString());
        }
        checkpanic caller->complete();
    }

    isolated remote function testFloat(HelloWorld100FloatCaller caller, float salary) {
        io:println("gross salary: " + salary.toString());
        float netSalary = salary * 0.88;
        Error? err = caller->send(netSalary);
        if (err is Error) {
            io:println("Error from Connector: " + err.message());
        } else {
            io:println("net salary : " + netSalary.toString());
        }
        checkpanic caller->complete();
    }

    isolated remote function testBoolean(HelloWorld100BooleanCaller caller, boolean available) {
        io:println("is available: " + available.toString());
        boolean aval = available || true;
        Error? err = caller->send(aval);
        if (err is Error) {
            io:println("Error from Connector: " + err.message());
        } else {
            io:println("avaliability : " + aval.toString());
        }
        checkpanic caller->complete();
    }

    isolated remote function testStruct(HelloWorld100ResponseCaller caller, Request msg) {
        io:println(msg.name + " : " + msg.message);
        Response response = {resp:"Acknowledge " + msg.name};
        Error? err = caller->send(response);
        if (err is Error) {
            io:println("Error from Connector: " + err.message());
        } else {
            io:println("msg : " + response.resp);
        }
        checkpanic caller->complete();
    }

    isolated remote function testNoRequest(HelloWorld100StringCaller caller) {
        string resp = "service invoked with no request";
        Error? err = caller->send(resp);
        if (err is Error) {
            io:println("Error from Connector: " + err.message());
        } else {
            io:println("response : " + resp);
        }
        checkpanic caller->complete();
    }

    isolated remote function testNoResponse(HelloWorld100NilCaller caller, string msg) {
        io:println("Request: " + msg);
    }

    isolated remote function testResponseInsideMatch(HelloWorld100ResponseCaller caller, string msg) {
        io:println("Request: " + msg);
        Response? res = {resp:"Acknowledge " + msg};
        if (res is Response) {
            checkpanic caller->send(res);
        } else {
            checkpanic caller->sendError(error NotFoundError("No updates from that drone"));
        }
        checkpanic caller->complete();
    }
}

public client class HelloWorld100StringCaller {
    private Caller caller;

    public function init(Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function send(string response) returns Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(Error err) returns Error? {
        return self.caller->sendError(err);
    }

    isolated remote function complete() returns Error? {
        return self.caller->complete();
    }
}

public client class HelloWorld100IntCaller {
    private Caller caller;

    public function init(Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function send(int response) returns Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(Error err) returns Error? {
        return self.caller->sendError(err);
    }

    isolated remote function complete() returns Error? {
        return self.caller->complete();
    }
}

public client class HelloWorld100FloatCaller {
    private Caller caller;

    public function init(Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function send(float response) returns Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(Error err) returns Error? {
        return self.caller->sendError(err);
    }

    isolated remote function complete() returns Error? {
        return self.caller->complete();
    }
}

public client class HelloWorld100BooleanCaller {
    private Caller caller;

    public function init(Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function send(boolean response) returns Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(Error err) returns Error? {
        return self.caller->sendError(err);
    }

    isolated remote function complete() returns Error? {
        return self.caller->complete();
    }
}

public client class HelloWorld100ResponseCaller {
    private Caller caller;

    public function init(Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function send(Response response) returns Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(Error err) returns Error? {
        return self.caller->sendError(err);
    }

    isolated remote function complete() returns Error? {
        return self.caller->complete();
    }
}

public client class HelloWorld100NilCaller {
    private Caller caller;

    public function init(Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendError(Error err) returns Error? {
        return self.caller->sendError(err);
    }

    isolated remote function complete() returns Error? {
        return self.caller->complete();
    }
}

const string ROOT_DESCRIPTOR_7 = "0A1530375F756E6172795F7365727665722E70726F746F120C6772706373657276696365731A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F1A1B676F6F676C652F70726F746F6275662F656D7074792E70726F746F22370A075265717565737412120A046E616D6518012001280952046E616D6512180A076D65737361676518022001280952076D657373616765221E0A08526573706F6E736512120A047265737018012001280952047265737032C4040A0D48656C6C6F576F726C6431303012430A0568656C6C6F121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C756512430A0774657374496E74121B2E676F6F676C652E70726F746F6275662E496E74333256616C75651A1B2E676F6F676C652E70726F746F6275662E496E74333256616C756512450A0974657374466C6F6174121B2E676F6F676C652E70726F746F6275662E466C6F617456616C75651A1B2E676F6F676C652E70726F746F6275662E466C6F617456616C756512450A0B74657374426F6F6C65616E121A2E676F6F676C652E70726F746F6275662E426F6F6C56616C75651A1A2E676F6F676C652E70726F746F6275662E426F6F6C56616C7565123B0A0A7465737453747275637412152E6772706373657276696365732E526571756573741A162E6772706373657276696365732E526573706F6E736512450A0D746573744E6F5265717565737412162E676F6F676C652E70726F746F6275662E456D7074791A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C756512460A0E746573744E6F526573706F6E7365121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A162E676F6F676C652E70726F746F6275662E456D707479124F0A1774657374526573706F6E7365496E736964654D61746368121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A162E6772706373657276696365732E526573706F6E7365620670726F746F33";
isolated function getDescriptorMap7() returns map<string> {
    return {
        "07_unary_server.proto":"0A1530375F756E6172795F7365727665722E70726F746F120C6772706373657276696365731A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F1A1B676F6F676C652F70726F746F6275662F656D7074792E70726F746F22370A075265717565737412120A046E616D6518012001280952046E616D6512180A076D65737361676518022001280952076D657373616765221E0A08526573706F6E736512120A047265737018012001280952047265737032C4040A0D48656C6C6F576F726C6431303012430A0568656C6C6F121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C756512430A0774657374496E74121B2E676F6F676C652E70726F746F6275662E496E74333256616C75651A1B2E676F6F676C652E70726F746F6275662E496E74333256616C756512450A0974657374466C6F6174121B2E676F6F676C652E70726F746F6275662E466C6F617456616C75651A1B2E676F6F676C652E70726F746F6275662E466C6F617456616C756512450A0B74657374426F6F6C65616E121A2E676F6F676C652E70726F746F6275662E426F6F6C56616C75651A1A2E676F6F676C652E70726F746F6275662E426F6F6C56616C7565123B0A0A7465737453747275637412152E6772706373657276696365732E526571756573741A162E6772706373657276696365732E526573706F6E736512450A0D746573744E6F5265717565737412162E676F6F676C652E70726F746F6275662E456D7074791A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C756512460A0E746573744E6F526573706F6E7365121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A162E676F6F676C652E70726F746F6275662E456D707479124F0A1774657374526573706F6E7365496E736964654D61746368121C2E676F6F676C652E70726F746F6275662E537472696E6756616C75651A162E6772706373657276696365732E526573706F6E7365620670726F746F33",
        "google/protobuf/empty.proto":"0A1B676F6F676C652F70726F746F6275662F656D7074792E70726F746F120F676F6F676C652E70726F746F62756622070A05456D70747942760A13636F6D2E676F6F676C652E70726F746F627566420A456D70747950726F746F50015A276769746875622E636F6D2F676F6C616E672F70726F746F6275662F7074797065732F656D707479F80101A20203475042AA021E476F6F676C652E50726F746F6275662E57656C6C4B6E6F776E5479706573620670726F746F33",
        "google/protobuf/wrappers.proto":"0A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F120F676F6F676C652E70726F746F62756622230A0B446F75626C6556616C756512140A0576616C7565180120012801520576616C756522220A0A466C6F617456616C756512140A0576616C7565180120012802520576616C756522220A0A496E74363456616C756512140A0576616C7565180120012803520576616C756522230A0B55496E74363456616C756512140A0576616C7565180120012804520576616C756522220A0A496E74333256616C756512140A0576616C7565180120012805520576616C756522230A0B55496E74333256616C756512140A0576616C756518012001280D520576616C756522210A09426F6F6C56616C756512140A0576616C7565180120012808520576616C756522230A0B537472696E6756616C756512140A0576616C7565180120012809520576616C756522220A0A427974657356616C756512140A0576616C756518012001280C520576616C7565427C0A13636F6D2E676F6F676C652E70726F746F627566420D577261707065727350726F746F50015A2A6769746875622E636F6D2F676F6C616E672F70726F746F6275662F7074797065732F7772617070657273F80101A20203475042AA021E476F6F676C652E50726F746F6275662E57656C6C4B6E6F776E5479706573620670726F746F33"

    };
}
