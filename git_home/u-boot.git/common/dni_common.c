#include <common.h>
#include <config.h>
#include <dni_common.h>

#if defined(NETGEAR_BOARD_ID_SUPPORT)
#if defined(OPEN_SOURCE_ROUTER_SUPPORT) && defined(OPEN_SOURCE_ROUTER_ID)
int  image_match_open_source_fw_id (ulong fw_image_addr)
{
	char image_model_id[BOARD_MODEL_ID_LENGTH + 1];

	/*get hardward id from image */
	memset(image_model_id, 0, sizeof(image_model_id));
	board_get_image_info(fw_image_addr, "device", (char*)image_model_id);
	printf("MODEL ID on image: %s\n", image_model_id);

	if (strcmp(image_model_id, OPEN_SOURCE_ROUTER_ID) != 0) {
		printf("Firmware Image MODEL ID do not match open source firmware ID\n");
		return 0;
	}
	printf("Firmware Image MODEL ID matched open source firmware ID\n\n");
	return 1;
}
#endif
#endif	/* BOARD_ID */
