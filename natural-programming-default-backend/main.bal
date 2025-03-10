// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerinax/azure.openai.chat;

configurable chat:ConnectionConfig connectionConfig = ?;
configurable string serviceUrl = ?;
configurable string deploymentId = ?;
configurable string apiVersion = ?;
configurable string tokenUrl = ?;
configurable string clientId = ?;
configurable string redirectUri = ?;

final chat:Client chatClient = check new (connectionConfig, serviceUrl);
final http:Client tokenClient = check new (tokenUrl);

type CreateChatCompletionRequest chat:CreateChatCompletionRequest;
type CreateChatCompletionResponse chat:CreateChatCompletionResponse;

service / on new http:Listener(8080) {
    resource function post chat/complete(CreateChatCompletionRequest chatBody) 
            returns CreateChatCompletionResponse|http:InternalServerError {
        chat:CreateChatCompletionResponse|error chatResult =
            chatClient->/deployments/[deploymentId]/chat/completions.post(apiVersion, chatBody);

        if chatResult is chat:CreateChatCompletionResponse {
            return chatResult;
        }

        log:printError("Chat completion failed", chatResult);
        return {body: "Chat completion failed"};
    }
    

    resource function get . (string code) returns json|http:InternalServerError {
        record {
            string access_token;
        }|error res = tokenClient->post("/", {
            code,
            grant_type: "authorization_code",
            client_id: clientId,
            redirect_uri: redirectUri
        }, mediaType = mime:APPLICATION_FORM_URLENCODED);

        if res is error {
            return http:INTERNAL_SERVER_ERROR;
        }
        return {access_token: res.access_token};
    }
}
