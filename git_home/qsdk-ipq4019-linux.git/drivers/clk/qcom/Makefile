KBUILD_CFLAGS := $(filter-out -O%,$(KBUILD_CFLAGS)) -O3

obj-$(CONFIG_COMMON_CLK_QCOM) += clk-qcom.o

clk-qcom-y += common.o
clk-qcom-y += clk-rpm.o
clk-qcom-y += clk-regmap.o
clk-qcom-y += clk-pll.o
clk-qcom-y += clk-rcg.o
clk-qcom-y += clk-rcg2.o
clk-qcom-y += clk-branch.o
clk-qcom-y += clk-generic.o
clk-qcom-$(CONFIG_KRAIT_CLOCKS) += clk-krait.o
clk-qcom-y += clk-hfpll.o
clk-qcom-y += clk-qcapll.o
clk-qcom-y += reset.o
clk-qcom-y += fab_scaling.o

obj-$(CONFIG_APQ_GCC_8084) += gcc-apq8084.o
obj-$(CONFIG_APQ_MMCC_8084) += mmcc-apq8084.o
obj-$(CONFIG_IPQ_GCC_806X) += gcc-ipq806x.o
obj-$(CONFIG_IPQ_GCC_806X) += nss-volt-ipq806x.o
obj-$(CONFIG_MSM_GCC_8660) += gcc-msm8660.o
obj-$(CONFIG_MSM_GCC_8960) += gcc-msm8960.o
obj-$(CONFIG_MSM_GCC_8974) += gcc-msm8974.o
obj-$(CONFIG_MSM_MMCC_8960) += mmcc-msm8960.o
obj-$(CONFIG_MSM_MMCC_8974) += mmcc-msm8974.o
obj-$(CONFIG_KPSS_XCC) += kpss-xcc.o
obj-$(CONFIG_QCOM_HFPLL) += hfpll.o
obj-$(CONFIG_KRAITCC) += krait-cc.o
obj-$(CONFIG_IPQ_GCC_40XX) += gcc-ipq40xx.o
obj-$(CONFIG_IPQ_ADCC_40XX) += adcc-ipq40xx.o
obj-$(CONFIG_DUMMY_CLK) += gcc-dummy.o
