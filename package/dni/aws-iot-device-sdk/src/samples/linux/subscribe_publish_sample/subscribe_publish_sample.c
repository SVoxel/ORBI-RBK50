/*
 * Copyright 2010-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

/**
 * @file subscribe_publish_sample.c
 * @brief simple MQTT publish and subscribe on the same topic
 *
 * This example takes the parameters from the aws_iot_config.h file and establishes a connection to the AWS IoT MQTT Platform.
 * It subscribes and publishes to the same topic - "sdkTest/sub"
 *
 * If all the certs are correct, you should see the messages received by the application in a loop.
 *
 * The application takes in the certificate path, host name , port and the number of times the publish should happen.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>

#include "aws_iot_config.h"
#include "aws_iot_log.h"
#include "aws_iot_version.h"
#include "aws_iot_mqtt_client_interface.h"

#define JSON_FILE       "/tmp/aws_json"
//#define JSON_FILE_SATELLITE       "/tmp/aws_satellite_json"

static char json[800000];
//static char sjson[4096];
static char clientKey[4096];

char *read_json(char *file)
{
	static char buf[800000] = {0}, temp[256] = {0};
	FILE *fp;
	int i = 0;
	buf[0] = '\0';
	fp = fopen(file, "r");
	if(fp == NULL)
		return buf;
	while(fgets(temp, sizeof(temp), fp))
		strcat(buf, temp);
	fclose(fp);
/*	while(buf[i] != '\r' &&  buf[i] != '\0' && buf[i] != '\n')
		i++;
	buf[i] = '\0';
*/
	return buf;
}

/**
 * @brief Default cert location
 */
char certDirectory[PATH_MAX + 1] = "/etc/router_analytics";

/**
 * @brief Default MQTT HOST URL is pulled from the aws_iot_config.h
 */
char HostAddress[255] = AWS_IOT_MQTT_HOST;

char ClientID[255] = AWS_IOT_MQTT_CLIENT_ID;

char TOPIC[128] = "analytics/";
/**
 * @brief Default MQTT port is pulled from the aws_iot_config.h
 */
uint32_t port = AWS_IOT_MQTT_PORT;

/**
 * @brief This parameter will avoid infinite loop of publish and exit the program after certain number of publishes
 */
uint32_t publishCount = 0;

uint32_t ra_debug_flag = 0;

void iot_subscribe_callback_handler(AWS_IoT_Client *pClient, char *topicName, uint16_t topicNameLen,
									IoT_Publish_Message_Params *params, void *pData) {
	IOT_UNUSED(pData);
	IOT_UNUSED(pClient);
	IOT_INFO("Subscribe callback");
	IOT_INFO("%.*s\t%.*s", topicNameLen, topicName, (int) params->payloadLen, params->payload);
}

void disconnectCallbackHandler(AWS_IoT_Client *pClient, void *data) {
	IOT_WARN("MQTT Disconnect");
	IoT_Error_t rc = FAILURE;

	if(NULL == pClient) {
		return;
	}

	IOT_UNUSED(data);

	if(aws_iot_is_autoreconnect_enabled(pClient)) {
		IOT_INFO("Auto Reconnect is enabled, Reconnecting attempt will start now");
	} else {
		IOT_WARN("Auto Reconnect not enabled. Starting manual reconnect...");
		rc = aws_iot_mqtt_attempt_reconnect(pClient);
		if(NETWORK_RECONNECTED == rc) {
			IOT_WARN("Manual Reconnect Successful");
		} else {
			IOT_WARN("Manual Reconnect Failed - %d", rc);
		}
	}
}

void parseInputArgsForConnectParams(int argc, char **argv) {
	int opt;

	while(-1 != (opt = getopt(argc, argv, "h:p:c:x:k:t:i:d:"))) {
		switch(opt) {
			case 'h':
				strcpy(HostAddress, optarg);
				IOT_DEBUG("Host %s", optarg);
				break;
			case 'i':
				strcpy(ClientID, optarg);
				IOT_DEBUG("clinet id %s", optarg);
				break;
			case 'p':
				port = atoi(optarg);
				IOT_DEBUG("arg %s", optarg);
				break;
			case 'c':
				strcpy(certDirectory, optarg);
				IOT_DEBUG("cert root directory %s", optarg);
				break;
			case 'x':
				publishCount = atoi(optarg);
				IOT_DEBUG("publish %s times\n", optarg);
				break;
			case 'k':
				strcpy(clientKey, optarg);
				break;
			case 't':
				strcpy(TOPIC, optarg);
				break;
			case 'd':
				ra_debug_flag = atoi(optarg);
				break;
			case '?':
				if(optopt == 'c') {
					IOT_ERROR("Option -%c requires an argument.", optopt);
				} else if(isprint(optopt)) {
					IOT_WARN("Unknown option `-%c'.", optopt);
				} else {
					IOT_WARN("Unknown option character `\\x%x'.", optopt);
				}
				break;
			default:
				IOT_ERROR("Error in command line argument parsing");
				break;
		}
	}

}

int main(int argc, char **argv) {
	bool infinitePublishFlag = true;

	char rootCA[PATH_MAX + 1];
	char clientCRT[PATH_MAX + 1];
	char cPayload[AWS_IOT_MQTT_TX_BUF_LEN];
	char cmd[256];
	int32_t i = 0, count = 3, pid, publish_flag=0;
	FILE *pidfp;

	if(access("/var/run/publish.pid", 0) != -1)
	{
		IOT_DEBUG("publish  already running!!!, please waitting!");
		return 0;
	}
	else 
	{
		pid = getpid();
		if ((pidfp = fopen("/var/run/publish.pid", "w")) != NULL) {
			fprintf(pidfp, "%d\n", pid);
			fclose(pidfp);
		}
	}

	strcpy(json, read_json(JSON_FILE));
//	strcpy(sjson, read_json(JSON_FILE_SATELLITE));

	IoT_Error_t rc = FAILURE;

	AWS_IoT_Client client;
	IoT_Client_Init_Params mqttInitParams = iotClientInitParamsDefault;
	IoT_Client_Connect_Params connectParams = iotClientConnectParamsDefault;

	IoT_Publish_Message_Params paramsQOS0;
	IoT_Publish_Message_Params paramsQOS1;

	parseInputArgsForConnectParams(argc, argv);

	IOT_INFO("\nAWS IoT SDK Version %d.%d.%d-%s\n", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH, VERSION_TAG);

	snprintf(rootCA, PATH_MAX + 1, "%s/%s", certDirectory, AWS_IOT_ROOT_CA_FILENAME);
	snprintf(clientCRT, PATH_MAX + 1, "%s/%s", certDirectory, AWS_IOT_CERTIFICATE_FILENAME);

	IOT_DEBUG("rootCA %s", rootCA);
	IOT_DEBUG("clientCRT %s", clientCRT);
	mqttInitParams.enableAutoReconnect = false; // We enable this later below
	mqttInitParams.pHostURL = HostAddress;
	mqttInitParams.port = port;
	mqttInitParams.pRootCALocation = rootCA;
	mqttInitParams.pDeviceCertLocation = clientCRT;
	mqttInitParams.pDevicePrivateKeyLocation = clientKey;
	mqttInitParams.mqttCommandTimeout_ms = 20000;
	mqttInitParams.tlsHandshakeTimeout_ms = 5000;
	mqttInitParams.isSSLHostnameVerify = true;
	mqttInitParams.disconnectHandler = disconnectCallbackHandler;
	mqttInitParams.disconnectHandlerData = NULL;

	rc = aws_iot_mqtt_init(&client, &mqttInitParams);
	if(SUCCESS != rc) {
		IOT_ERROR("aws_iot_mqtt_init returned error : %d ", rc);
		goto fin;
	}

	connectParams.keepAliveIntervalInSec = 10;
	connectParams.isCleanSession = true;
	connectParams.MQTTVersion = MQTT_3_1_1;
	connectParams.pClientID = ClientID;
	connectParams.clientIDLen = (uint16_t) strlen(ClientID);
	connectParams.isWillMsgPresent = false;

	IOT_INFO("Connecting...");
	rc = aws_iot_mqtt_connect(&client, &connectParams);
	if(SUCCESS != rc) {
		goto fin;
	}
	/*
	 * Enable Auto Reconnect functionality. Minimum and Maximum time of Exponential backoff are set in aws_iot_config.h
	 *  #AWS_IOT_MQTT_MIN_RECONNECT_WAIT_INTERVAL
	 *  #AWS_IOT_MQTT_MAX_RECONNECT_WAIT_INTERVAL
	 */
	rc = aws_iot_mqtt_autoreconnect_set_status(&client, true);
	if(SUCCESS != rc) {
		IOT_ERROR("Unable to set Auto Reconnect to true - %d", rc);
		goto fin;
	}
/*
	IOT_INFO("Subscribing...");
	rc = aws_iot_mqtt_subscribe(&client, "RBR50/update", 12, QOS0, iot_subscribe_callback_handler, NULL);
	if(SUCCESS != rc) {
		IOT_ERROR("Error subscribing : %d ", rc);
		return rc;
	}
*/
//	sprintf(cPayload, "%s : %d ", "hello from SDK", i);
	sprintf(cPayload, "{\n%s}\n", json);

	paramsQOS0.qos = QOS0;
	paramsQOS0.payload = (void *) cPayload;
	paramsQOS0.isRetained = 0;

	paramsQOS1.qos = QOS1;
	paramsQOS1.payload = (void *) cPayload;
	paramsQOS1.isRetained = 0;

	if(publishCount != 0) {
		infinitePublishFlag = false;
	}

	while((NETWORK_ATTEMPTING_RECONNECT == rc || NETWORK_RECONNECTED == rc || SUCCESS == rc)
		&& (publishCount > 0 || infinitePublishFlag) && !ra_debug_flag){

		rc = aws_iot_mqtt_yield(&client, 100);
		if(NETWORK_ATTEMPTING_RECONNECT == rc) {
			continue;
		}

		IOT_INFO("-->sleep");
		sleep(1);
		sprintf(cPayload, "{\n%s}\n", json);
		IOT_INFO("Publish data\n %s", cPayload);
		paramsQOS0.payloadLen = strlen(cPayload);
		IOT_INFO("Publish Info to TOPIC %s\n", TOPIC);
		rc = aws_iot_mqtt_publish(&client, TOPIC, 10, &paramsQOS0);
		if(publishCount > 0) {
			publishCount--;
		}
	}
	while((NETWORK_ATTEMPTING_RECONNECT == rc || NETWORK_RECONNECTED == rc || SUCCESS == rc)
		&& (publishCount > 0 || infinitePublishFlag) && ra_debug_flag){

		rc = aws_iot_mqtt_yield(&client, 100);
		if(NETWORK_ATTEMPTING_RECONNECT == rc) {
			continue;
		}

		IOT_INFO("-->sleep");
		sleep(1);
		int i=0, j=0;
		char file[32] = {0};
		for(i=1;;i++){
			snprintf(file, sizeof(file)-1, "%s%d", JSON_FILE, i);
			strcpy(json, read_json(file));
			if(json[0] != '\0'){
				sprintf(cPayload, "%s\n", json);
				IOT_INFO("Publish data\n %s", cPayload);
				paramsQOS0.payloadLen = strlen(cPayload);
				IOT_INFO("Publish Info to TOPIC %s\n", TOPIC);
				rc = aws_iot_mqtt_publish(&client, TOPIC, 10, &paramsQOS0);
				publish_flag=1;
				if(SUCCESS == rc)
					continue;
				else {
					publishCount--;
					for(j=0;j<publishCount;j++){ /*retry publishCount times*/
						sleep(60);
						rc = aws_iot_mqtt_publish(&client, TOPIC, 10, &paramsQOS0);
						if(SUCCESS == rc)   /*if sucess continue publish next json */
							break;
					}
					if(SUCCESS != rc) /*after retry publishCount times, break and stop to publish */
						break;
				}
			} else {
				publishCount=0;
				break;
			}
				
		}
		if(publish_flag)
			system("rm /tmp/ra_debug_tmp.log* /tmp/ra_debug.log");
	}
fin:
	if(SUCCESS != rc) {
		IOT_ERROR("An error occurred  %d", rc);
	} else {
		IOT_INFO("Publish done\n");
	}

	if(ra_debug_flag) {
		system("rm /tmp/aws_json*");
		system("rm /tmp/ra_debug_tmp.log*");
	}
	sprintf(cmd, "echo %d >/tmp/publish_status", rc);
	system(cmd);
	system("rm -rf /var/run/publish.pid");
	return rc;
}
