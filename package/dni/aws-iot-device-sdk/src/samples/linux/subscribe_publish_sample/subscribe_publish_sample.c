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
#include <dirent.h>

#include "aws_iot_config.h"
#include "aws_iot_log.h"
#include "aws_iot_version.h"
#include "aws_iot_mqtt_client_interface.h"
#include "JSON_checker.h"

#define JSON_FILE       "/tmp/aws_json"
#define INSTALL_FILES       "/tmp/router-analytics/ra_data/installation"
//#define JSON_FILE_SATELLITE       "/tmp/aws_satellite_json"

static char json[800000];
//static char sjson[4096];
static char clientKey[4096];
static char filename[24];

int check_json()
{
    JSON_checker jc = new_JSON_checker(20);

	FILE *fp, *ofp;
	int c;
	int fail = 0;
	char cmd[256] = {0};
	snprintf(cmd, sizeof(cmd), " mv /tmp/aws_json %s", filename);
	system(cmd);

	if((fp=fopen(filename, "r")) != NULL && (ofp=fopen("/tmp/aws_json", "w")) != NULL )
	{
		while((c = fgetc(fp)) != EOF){
			if (fail == 0 && !JSON_checker_char(jc, c)) {
				fprintf(stderr, "JSON_checker_char: ==%c== syntax error\n", c);
				fail=1;
			} else
				fputc(c, ofp);
		}
		fclose(fp);
		fclose(ofp);
		if (!JSON_checker_done(jc)) {
			fprintf(stderr, "JSON_checker_end: syntax error\n");
			fail=1;
		} 
	}
	if(fail==0){
		snprintf(cmd, sizeof(cmd), " rm %s", filename);
		system(cmd);
	}
	return fail;
}

void read_json(char *file)
{
	char temp[512] = {0};
	FILE *fp;
	int i = 0;
	memset(json, 0, sizeof(json));
	fp = fopen(file, "r");
	if(fp != NULL) {
		while(fgets(temp, sizeof(temp), fp))
			strcat(json, temp);
		fclose(fp);
	}
/*	while(buf[i] != '\r' &&  buf[i] != '\0' && buf[i] != '\n')
		i++;
	buf[i] = '\0';
*/
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

//uint32_t ra_debug_flag = 0;
uint32_t installation_count = 5;
uint32_t installation=0;

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

	while(-1 != (opt = getopt(argc, argv, "h:p:c:x:k:t:i:n:e:a:"))) {
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
			case 'n':
				installation_count = atoi(optarg);
				break;
			case 'a':
				installation=1;
				break;
			case 'e':
				strcpy(filename, optarg);
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

int filer_file(const struct dirent *ent)
{
	if(ent->d_type == 8)
		return 1;
	else
		return 0;
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

	IoT_Error_t rc = FAILURE;

	AWS_IoT_Client client;
	IoT_Client_Init_Params mqttInitParams = iotClientInitParamsDefault;
	IoT_Client_Connect_Params connectParams = iotClientConnectParamsDefault;

	IoT_Publish_Message_Params paramsQOS0;

	parseInputArgsForConnectParams(argc, argv);

	if(!installation) {
		if(check_json()){
			if(check_json()) {
				goto fin;
			} else
				read_json(JSON_FILE);
		} else
			read_json(JSON_FILE);
	}

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
	if(!installation) 
		sprintf(cPayload, "%s", json);

	paramsQOS0.qos = QOS0;
	paramsQOS0.payload = (void *) cPayload;
	paramsQOS0.isRetained = 0;

	if(publishCount != 0) {
		infinitePublishFlag = false;
	}

	if(!installation) {
		while((NETWORK_ATTEMPTING_RECONNECT == rc || NETWORK_RECONNECTED == rc || SUCCESS == rc)
			&& (publishCount > 0 || infinitePublishFlag)){

			rc = aws_iot_mqtt_yield(&client, 100);
			if(NETWORK_ATTEMPTING_RECONNECT == rc) {
				continue;
			}

			IOT_INFO("-->sleep");
			sleep(1);
			sprintf(cPayload, "%s", json);
			IOT_INFO("Publish data\n %s", cPayload);
			paramsQOS0.payloadLen = strlen(cPayload);
			IOT_INFO("Publish Info to TOPIC %s\n", TOPIC);
			rc = aws_iot_mqtt_publish(&client, TOPIC, 10, &paramsQOS0);
			if(publishCount > 0) {
				publishCount--;
			}
		}
	} else {
		int i=0, j=0, num=0, n=0;
		struct dirent **ptr;
		char cmd[1024] = {0};
		num=scandir(INSTALL_FILES, &ptr, filer_file, alphasort);
		if(num > 0) {
			rc = aws_iot_mqtt_yield(&client, 100);
			while(n<num) {
				if(ptr[n]->d_type == 8)  {
					i=publishCount;
					rc=NETWORK_ATTEMPTING_RECONNECT;
					while((NETWORK_ATTEMPTING_RECONNECT == rc || NETWORK_RECONNECTED == rc || SUCCESS == rc)
					&& (i > 0 || infinitePublishFlag)){

						if( NETWORK_RECONNECTED == rc) {
							rc = aws_iot_mqtt_yield(&client, 100);
							continue;
						}

						snprintf(cmd, sizeof(cmd)-1, "%s/%s", INSTALL_FILES, ptr[n]->d_name);
						read_json(cmd);
						sprintf(cPayload, "%s", json);
						IOT_INFO("Publish data\n %s", cPayload);
						paramsQOS0.payloadLen = strlen(cPayload);
						IOT_INFO("Publish Info to TOPIC %s\n", TOPIC);
						rc = aws_iot_mqtt_publish(&client, TOPIC, 10, &paramsQOS0);
						if(i>0)
							i--;
					}
					if(rc ==SUCCESS) {
						snprintf(cmd, sizeof(cmd)-1, "rm %s/%s", INSTALL_FILES, ptr[n]->d_name);
						system(cmd);
					}
					j++;
					free(ptr[n]);
					n++;
					if( !installation && j>=installation_count){
						break;
					}
				}
			}
			free(ptr);
		}
	}
fin:
	if(SUCCESS != rc) {
		IOT_ERROR("An error occurred  %d", rc);
	} else {
		IOT_INFO("Publish done\n");
	}
	sprintf(cmd, "echo %d >/tmp/publish_status", rc);
	system(cmd);
	system("rm -rf /var/run/publish.pid");
	return rc;
}
