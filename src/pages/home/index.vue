<template>
    <div class="home">
        <video class="video" src="/images/video.mp4" poster="~images/home/mask.png" autoplay loop muted playsinline></video>
        <div class="invite">
            <div class="title">邀请将士加入赤壁战场</div>
            <div class="content">
                <div class="lib">
                    邀请链接：{{ showInviterLink ? '--' : $hash(inviterLink, 20, 7) }}
                    <div v-if="!showInviterLink" @click="$copy(inviterLink)">复制链接</div>
                </div>
                <div class="lib">已邀请数：{{ state.userInfo.sons }}人</div>
                <div class="lib">已获奖励：{{ state.userInfo.rewards }} USDT</div>
                <p>PS：一代奖励7%，二代奖励3%，奖励直接进入邀请人地址</p>
            </div>
        </div>
        <div class="stake">
            <div class="title">参加赤壁之战质押</div>
            <div class="content">
                <p class="balance">余额：{{ state.balance }}</p>
                <div class="section">
                    <div class="left">
                        <img src="~images/home/104.png" alt="" />
                        <input type="text" placeholder="0.0" disabled v-model="state.amount" @input="keyupAmount" />
                        <span>USDT</span>
                    </div>
                    <div class="right">
                        <el-popover popper-class="menu-popover" trigger="click" placement="bottom-end" v-model:visible="state.daysPopoverVisible">
                            <template #reference>
                                <div class="days" :class="{ disabled: state.days === '' }">
                                    {{ state.days ? state.days + '天' : '请选择' }}
                                    <i class="iconfont">&#xe6f7;</i>
                                </div>
                            </template>
                            <div class="menu-list">
                                <div v-for="(item, index) in state.days_list" :key="index" class="item" @click="handleDaysSelect(item.value)">
                                    {{ item.label }}
                                </div>
                            </div>
                        </el-popover>
                    </div>
                </div>
                <div class="amounts">
                    <div v-for="value in state.amountList" :key="value" :class="{ active: state.amount === value }" @click="state.amount = value">{{ value }} USDT</div>
                </div>
                <el-button v-if="isNeedApprove" :loading="state.approveLoading" @click="approve()">授权</el-button>
                <el-button v-else :disabled="btn_disable" :loading="state.loading" @click="handleStake()">
                    {{ stakeBtnText }}
                </el-button>

                <div class="tip">当日质押 {{ state.getStakedToday }} USDT / 当日限额 {{ state.maxSupplyPerDay }} USDT</div>
            </div>
        </div>

        <div class="reward">
            <div class="title">草船借箭15天战役</div>
            <div class="content">
                <div>我的质押：{{ state.userInfo.balance15 }} USDT</div>
                <div>倒计时：{{ state.userInfo.time15Diff.days }}天{{ state.userInfo.time15Diff.hours }}小时{{ state.userInfo.time15Diff.minutes }}分钟{{ state.userInfo.time15Diff.seconds }}秒</div>
                <div>收益表：{{ state.pendingReward15 }} USDT</div>
            </div>
            <el-button :loading="state.claim15Loading" :disabled="claim15Disabled" @click="handleClaim(15)">到期领币</el-button>
        </div>
        <div class="reward">
            <div class="title">火烧赤壁30天战役</div>
            <div class="content">
                <div>我的质押：{{ state.userInfo.balance30 }} USDT</div>
                <div>倒计时：{{ state.userInfo.time30Diff.days }}天{{ state.userInfo.time30Diff.hours }}小时{{ state.userInfo.time30Diff.minutes }}分钟{{ state.userInfo.time30Diff.seconds }}秒</div>
                <div>收益表：{{ state.pendingReward30 }} USDT</div>
            </div>
            <el-button :loading="state.claim30Loading" :disabled="claim30Disabled" @click="handleClaim(30)">到期领币</el-button>
        </div>
        <div class="price">
            <img src="~images/home/205.png" alt="" />
            $ {{ state.zyPrice }} USDT
        </div>

        <p class="copyright">2025@ZY Copyright All Rights Reserved</p>
    </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, watch, onBeforeUnmount, computed, ref } from 'vue';
import { ElMessage } from 'element-plus';
import { useBlockChain } from '@/store/chain';
import { $BigNumber, $shiftedByFixed, $hash, $copy, $numFormat, $filterNumberVal, $onlyNumber, $momentTimes, $filterNumber } from '@/utils/met';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const blockChain = useBlockChain();

const timer = ref(null);

const inviterInput = ref('');

const state = reactive({
    amountList: [100, 200, 500, 1000, 2000],
    days_list: [
        {
            label: '15 天',
            value: 15,
        },
        {
            label: '30 天',
            value: 30,
        },
    ],
    days: 15 as string | number,

    amount: 100 as string | number,

    balance: '--' as string | number,
    approveLoading: false,
    allowance: 0,
    loading: false,

    claim15Loading: false,
    claim30Loading: false,

    start: false,

    minAmount: 100,
    maxAmount: 2000,

    pendingReward15: '--' as string | number,
    pendingReward30: '--' as string | number,
    zyPrice: '--' as string | number,

    maxSupplyPerDay: '--' as string | number,
    getStakedToday: '--' as string | number,

    shareid: '',
    daysPopoverVisible: false,
    userInfo: {
        balance15: '--',
        balance30: '--',
        startTime15: '--',
        startTime30: '--',
        sons: '--',
        rewards: '--',
        inviter: '--',
        time15Diff: {
            days: '--',
            hours: '-',
            minutes: '-',
            seconds: '-',
        },
        time30Diff: {
            days: '-',
            hours: '-',
            minutes: '-',
            seconds: '-',
        },
    } as any,
});

watch(
    () => blockChain.chainId,
    () => {
        init();
    }
);
watch(
    () => blockChain.account,
    () => {
        init();
    }
);

const showInviterLink = computed(() => {
    return state.userInfo.sons === '--' || (state.userInfo.balance15 === 0 && state.userInfo.balance30 === 0);
});
const claim15Disabled = computed(() => {
    return state.pendingReward15 === '--' || !state.pendingReward15 || Object.values(state.userInfo.time15Diff).reduce((acc: number, item) => acc + Number(item || 0), 0) > 0;
});
const claim30Disabled = computed(() => {
    return state.pendingReward30 === '--' || !state.pendingReward30 || Object.values(state.userInfo.time30Diff).reduce((acc: number, item) => acc + Number(item || 0), 0) > 0;
});

const inviterLink = computed(() => {
    return `${blockChain.link.web_url}?id=${blockChain.account}`;
});
const isNeedApprove = computed(() => {
    if (state.amount === '') return false;
    return $BigNumber(state.amount).gt(state.allowance);
});

const btn_disable = computed(() => {
    return (
        !state.amount ||
        !state.start ||
        state.userInfo.sons === '--' || //
        (state.days === 15 && state.userInfo.balance15 > 0) ||
        (state.days === 30 && state.userInfo.balance30 > 0) ||
        $BigNumber(Number(state.amount) + Number(state.getStakedToday)).gt(Number(state.maxSupplyPerDay))
    );
});

const stakeBtnText = computed(() => {
    if (state.days === 15 && state.userInfo.balance15 > 0) return '已参加';
    if (state.days === 30 && state.userInfo.balance30 > 0) return '已参加';
    return state.start ? '参加' : '暂停参与';
});

const keyupAmount = () => {
    state.amount = $onlyNumber(state.amount);
};

const handleDaysSelect = (value: number) => {
    // if (value === 15 && state.userInfo.balance15 > 0) return;
    // if (value === 30 && state.userInfo.balance30 > 0) return;
    state.days = value;
    state.daysPopoverVisible = false;
};

const getBalance = async () => {
    try {
        const [token] = await Promise.all([
            blockChain.getBalance(blockChain.contract_address[blockChain.chainId].usdtContract, blockChain.account), //
        ]);
        state.balance = $shiftedByFixed(token, -18, 0);
    } catch (e: any) {
        ElMessage({
            showClose: true,
            message: e.message,
            type: 'error',
            duration: 5000,
        });
    }
};

const getAllowance = async () => {
    try {
        const tokenAllowance = await blockChain.getAllowance(blockChain.contract_address[blockChain.chainId].usdtContract, blockChain.contract_address[blockChain.chainId].mineContract);
        state.allowance = $shiftedByFixed(tokenAllowance, -18, 3);
        console.log('tokenAllowance::', state.allowance);
    } catch (e: any) {
        ElMessage({
            showClose: true,
            message: e.message,
            type: 'error',
            duration: 5000,
        });
    }
};

const approve = async () => {
    try {
        state.approveLoading = true;
        const amount = $BigNumber(state.amount).shiftedBy(18).toFixed();

        const result = await blockChain.approve(
            blockChain.contract_address[blockChain.chainId].mineContract, //
            blockChain.contract_address[blockChain.chainId].usdtContract,
            amount
        );
        if (result) {
            ElMessage({
                showClose: true,
                message: t('base.Approve SucceccFuly'),
                type: 'success',
                duration: 2500,
            });
            getAllowance();
        } else {
            ElMessage({
                showClose: true,
                message: t('base.Approve Fail'),
                type: 'error',
                duration: 2500,
            });
        }
    } catch (e: any) {
        ElMessage({
            showClose: true,
            message: e?.reason ?? e?.message ?? 'Error',
            type: 'error',
            duration: 2500,
        });
    } finally {
        state.approveLoading = false;
    }
};

const getBaseInfo1 = async () => {
    try {
        const contract = blockChain.getMineContract();
        const [
            start, //
            minAmount,
            maxAmount,
            userInfo,
            pendingReward15,
            pendingReward30,
        ] = await Promise.all([
            contract.start(), //
            contract.minAmount(),
            contract.maxAmount(),
            contract.userInfo(blockChain.account),
            contract.pendingReward15(blockChain.account),
            contract.pendingReward30(blockChain.account),
        ]);
        state.userInfo = {
            balance15: $shiftedByFixed(userInfo.balance15.toString(), -18, 2),
            balance30: $shiftedByFixed(userInfo.balance30.toString(), -18, 2),
            startTime15: Number(userInfo.startTime15.toString()) * 1000,
            startTime30: Number(userInfo.startTime30.toString()) * 1000,
            sons: Number(userInfo.sons.toString()),
            rewards: $shiftedByFixed(userInfo.rewards.toString(), -18, 2),
            inviter: userInfo.inviter === '0x0000000000000000000000000000000000000000' ? '--' : userInfo.inviter,

            time15Diff: $momentTimes(state.userInfo.startTime15 + 15 * 24 * 60 * 60 * 1000),
            time30Diff: $momentTimes(state.userInfo.startTime30 + 30 * 24 * 60 * 60 * 1000),
        };
        state.start = start;
        state.minAmount = $shiftedByFixed(minAmount.toString(), -18, 0);
        state.maxAmount = $shiftedByFixed(maxAmount.toString(), -18, 0);
        state.pendingReward15 = $shiftedByFixed(pendingReward15.toString(), -18, 6);
        state.pendingReward30 = $shiftedByFixed(pendingReward30.toString(), -18, 6);
        if (state.userInfo.startTime15 || state.userInfo.startTime30) loopTime();
        if (state.userInfo.balance15 === 0) state.days = 15;
        else if (state.userInfo.balance30 === 0) state.days = 30;
        else clearInterval(timer.value);
    } catch (e: any) {}
};

const getBaseInfo = async () => {
    try {
        const contract = blockChain.getMineContract();
        const multicallContract = blockChain.getMulticallContract();

        // 准备multicall调用数据
        const calls = [
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('start'),
            },
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('maxSupplyPerDay'),
            },
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('getStakedToday'),
            },
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('minAmount'),
            },
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('maxAmount'),
            },
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('userInfo', [blockChain.account]),
            },
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('pendingReward15', [blockChain.account]),
            },
            {
                target: blockChain.contract_address[blockChain.chainId].mineContract,
                callData: contract.interface.encodeFunctionData('pendingReward30', [blockChain.account]),
            },
        ];

        const [blockNumber, returnData] = await multicallContract.callStatic.aggregate(calls);
        console.log('blockNumber::', blockNumber.toString());
        console.log('returnData::', returnData);

        const start = contract.interface.decodeFunctionResult('start', returnData[0])[0];
        const maxSupplyPerDay = contract.interface.decodeFunctionResult('maxSupplyPerDay', returnData[1])[0];
        const getStakedToday = contract.interface.decodeFunctionResult('getStakedToday', returnData[2])[0];
        const minAmount = contract.interface.decodeFunctionResult('minAmount', returnData[3])[0];
        const maxAmount = contract.interface.decodeFunctionResult('maxAmount', returnData[4])[0];
        const userInfo = contract.interface.decodeFunctionResult('userInfo', returnData[5]);
        const pendingReward15 = contract.interface.decodeFunctionResult('pendingReward15', returnData[6])[0];
        const pendingReward30 = contract.interface.decodeFunctionResult('pendingReward30', returnData[7])[0];
        // const [start, maxSupplyPerDay, getStakedToday, minAmount, maxAmount, userInfo, pendingReward15, pendingReward30] = returnData.map((data: string, index: number) => {
        //     if (index === 5) {
        //         // userInfo返回的是结构体，需要特殊处理
        //         return contract.interface.decodeFunctionResult('userInfo', data);
        //     } else {
        //         const functionNames = ['start', 'maxSupplyPerDay', 'getStakedToday', 'minAmount', 'maxAmount', 'userInfo', 'pendingReward15', 'pendingReward30'];
        //         return contract.interface.decodeFunctionResult(functionNames[index], data)[0];
        //     }
        // });

        // console.log('start::', start);
        // console.log('minAmount::', minAmount);
        // console.log('maxAmount::', maxAmount);
        // console.log('userInfo::', userInfo);
        // console.log('pendingReward15::', pendingReward15.toString());
        // console.log('pendingReward30::', pendingReward30.toString());

        state.userInfo = {
            balance15: $shiftedByFixed(userInfo.balance15.toString(), -18, 2),
            balance30: $shiftedByFixed(userInfo.balance30.toString(), -18, 2),
            startTime15: Number(userInfo.startTime15.toString()) * 1000,
            startTime30: Number(userInfo.startTime30.toString()) * 1000,
            sons: Number(userInfo.sons.toString()),
            rewards: $shiftedByFixed(userInfo.rewards.toString(), -18, 2),
            inviter: userInfo.inviter === '0x0000000000000000000000000000000000000000' ? '--' : userInfo.inviter,

            time15Diff: $momentTimes(state.userInfo.startTime15 + 15 * 24 * 60 * 60 * 1000),
            time30Diff: $momentTimes(state.userInfo.startTime30 + 30 * 24 * 60 * 60 * 1000),
        };
        state.start = start;
        state.maxSupplyPerDay = $shiftedByFixed(maxSupplyPerDay.toString(), -18, 0);
        state.getStakedToday = $shiftedByFixed(getStakedToday.toString(), -18, 0);
        state.minAmount = $shiftedByFixed(minAmount.toString(), -18, 0);
        state.maxAmount = $shiftedByFixed(maxAmount.toString(), -18, 0);
        state.pendingReward15 = $shiftedByFixed(pendingReward15.toString(), -18, 6);
        state.pendingReward30 = $shiftedByFixed(pendingReward30.toString(), -18, 6);
        if (state.userInfo.startTime15 || state.userInfo.startTime30) loopTime();
        // else clearInterval(timer.value);
        // if (state.userInfo.balance15 === 0) state.days = 15;
        // else if (state.userInfo.balance30 === 0) state.days = 30;

        // console.log('state.maxSupplyPerDay::', state.maxSupplyPerDay);
        // console.log('state.getStakedToday::', state.getStakedToday);
    } catch (e: any) {
        console.error('getBaseInfo error:', e);
    }
};

const getPrice = async () => {
    try {
        const contract = blockChain.getMineContract();
        const zyPrice = await contract.zyPrice();
        state.zyPrice = $shiftedByFixed(zyPrice.toString(), -18, 2);
    } catch (e: any) {}
};

const handleStake = async () => {
    try {
        if (state.userInfo.sons === '--') throw new Error(t('base.load data'));
        if ($BigNumber(state.amount).lt(state.minAmount)) throw new Error(`质押金额不能小于${state.minAmount} USDT`);
        if ($BigNumber(state.amount).gt(state.maxAmount)) throw new Error(`质押金额不能大于${state.maxAmount} USDT`);
        if ($BigNumber(state.balance).lt(state.amount)) throw new Error('余额不足');
        if (!state.days) throw new Error('请选择质押天数');
        state.loading = true;
        const override = {
            // value: $BigNumber(state.amount).shiftedBy(18).toFixed(),
            // gasLimit: $BigNumber(gas.toString()).multipliedBy(2).toFixed(0),
            // gasPrice: Number(gasPrice) + 1,
            gasLimit: 5000000,
        };
        const inviter = (state.userInfo.inviter === '--' ? state.shareid : state.userInfo.inviter) || '0x0000000000000000000000000000000000000000';

        console.log('stake::', inviter, state.amount, state.days);
        const contract = blockChain.getMineContract();
        let transferTx = await contract.stake(inviter, $BigNumber(state.amount).shiftedBy(18).toFixed(), state.days, override);
        const receipt = await transferTx.wait();
        if (receipt.status) {
            ElMessage({
                showClose: true,
                message: '质押成功',
                type: 'success',
                duration: 2500,
            });
            getAllowance();
            getBalance();
            getBaseInfo();
            state.amount = '';
        } else {
            throw new Error('质押失败');
        }
    } catch (e: any) {
        console.log('e::', e);
        ElMessage({
            showClose: true,
            message: e?.reason ?? e?.message ?? 'Error',
            type: 'error',
            duration: 2500,
        });
    } finally {
        state.loading = false;
    }
};

const handleClaim = async (days: number) => {
    try {
        if (days === 15) {
            state.claim15Loading = true;
        } else {
            state.claim30Loading = true;
        }
        // const override = {
        //     value: $BigNumber(state.amount).shiftedBy(18).toFixed(),
        //     gasLimit: $BigNumber(gas.toString()).multipliedBy(2).toFixed(0),
        //     gasPrice: Number(gasPrice) + 1,
        // };
        const contract = blockChain.getMineContract();
        let transferTx = days === 15 ? await contract.claim15() : await contract.claim30();
        const receipt = await transferTx.wait();
        if (receipt.status) {
            ElMessage({
                showClose: true,
                message: '领取成功',
                type: 'success',
                duration: 2500,
            });
            getBaseInfo();
        } else {
            throw new Error('领取失败');
        }
    } catch (e: any) {
        ElMessage({
            showClose: true,
            message: e?.reason ?? e?.message ?? 'Error',
            type: 'error',
            duration: 2500,
        });
    } finally {
        if (days === 15) {
            state.claim15Loading = false;
        } else {
            state.claim30Loading = false;
        }
    }
};

const loopTime = () => {
    clearInterval(timer.value);
    timer.value = setInterval(() => {
        state.userInfo.time15Diff = $momentTimes(state.userInfo.startTime15 + 15 * 24 * 60 * 60 * 1000);
        state.userInfo.time30Diff = $momentTimes(state.userInfo.startTime30 + 30 * 24 * 60 * 60 * 1000);
    }, 1000);
};

const init = async () => {
    if (blockChain.account && blockChain.chainId) {
        if (![97, 56].includes(Number(blockChain.chainId))) {
            ElMessage.error({
                message: t('change network'),
                duration: 7000,
            });
            return;
        }
        const inviter = blockChain.inviter || '';
        state.shareid = inviter === blockChain.account ? '' : inviter;
        await getAllowance();
        await getBalance();
        getPrice();
        getBaseInfo();
        // setInterval(() => {
        //     getPrice();
        // }, 3000);
    }
};

onMounted(() => {
    init();
});
onBeforeUnmount(() => {
    clearInterval(timer.value);
});
</script>

<style lang="scss">
.el-dialog {
    border-radius: 0.1rem;
    background: #531717;
    box-shadow: inset 0px 0 15px 0px #fd7513;
    border-radius: 0.25rem;
    max-width: 330px;
    &.black-dialog {
        .el-dialog__header {
            display: block;
            text-align: center;
            .el-dialog__title {
                font-weight: 700;
                font-size: 0.15rem;
                color: #ffee80;
                line-height: 1.5;
            }
        }
        .el-dialog__body {
            padding: 0.1rem 0.1rem 0rem;
            .inviter-input {
                width: 100%;
                font-size: 0.15rem;
                color: #000;
                border-radius: 0.08rem;
                border-color: #000;
                padding: 0.05rem 0.1rem;
                background: #ffebcd;
                border-radius: 8px 8px 8px 8px;
                border: none !important;
                outline: none !important;
                &::placeholder {
                    color: #707050;
                    font-size: 0.13rem;
                }
            }
        }
        .el-dialog__footer {
            display: flex;
            justify-content: center;
            padding-bottom: 0.1rem;
            button {
                width: 60%;
                border: none !important;
                height: 0.34rem;
                border-radius: 0.08rem;
                font-size: 0.15rem;
                color: #fff;
                background: #fd7513 !important;
            }
        }
    }
    .el-dialog__header {
        display: none;
    }
    .el-dialog__body {
        width: 100%;
        padding: 0.04rem 0.2rem 0.17rem;

        h5 {
            font-weight: 700;
            font-size: 0.18rem;
            color: #ffffff;
            line-height: 1.5;
            text-align: center;
            margin-bottom: 0.1rem;
        }
        p {
            text-align: right;
            font-size: 0.11rem;
            color: #ffffff;
            line-height: 1;
            margin: 0.07rem 0 0.05rem;
        }
        input {
            margin-bottom: 0.1rem;
            width: 100%;
            font-size: 0.15rem;
            color: #000;
            height: 0.4rem;
            border-radius: 0.08rem;
            border-color: #000;
            padding: 0 0.1rem;
            background: #ffebcd;
            border-radius: 8px 8px 8px 8px;
            &::placeholder {
                color: #707050;
                font-size: 0.13rem;
            }
        }
        .tip {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.11rem;
            color: #ffffff;
            line-height: 1.5;
            padding: 0 0.1rem;
            span {
            }
            .days {
                display: flex;
                align-items: center;
                gap: 0.06rem;
                i {
                    font-size: 0.12rem;
                }
            }
        }
        .btn {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 0.07rem;
            margin-top: 0.1rem;
            button {
                flex: 1;
                height: 0.34rem;
                border-radius: 0.08rem;
                border: none;
                font-size: 0.15rem;
                color: #fff;
                background: #fd7513;
            }
        }
    }
    .el-dialog__footer {
        display: flex;
        justify-content: center;
        button {
            width: 50%;
            height: 0.4rem;
            background: #efb813 !important;
            font-size: 0.14rem;
            color: #fff !important;
            border-radius: 0.2rem;
            border: none !important;
        }
    }
}

.menu-popover {
    background: #fff !important;
    border: none !important;
    border-radius: 0.04rem !important;
    padding: 0 !important;
    .el-popper__arrow {
        &::before {
            background: #fff !important;
            border-color: rgba(255, 255, 255, 0.2) !important;
        }
    }
    .menu-list {
        padding: 0.05rem 0 0.08rem;
        .item {
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: 0.13rem;
            color: #000;
            font-weight: 500;
            line-height: 1.8;
            margin-bottom: 0.05rem;
            transition: background-color 0.2s;
            &:last-child {
                border-bottom: none;
            }
            &:last-child {
                margin-bottom: 0;
            }
            &.active {
                background: #7fff00;
            }
            &.disabled {
                background: rgba(146, 145, 140, 0.8) !important;
            }
        }
    }
}
.address-dialog {
    .el-dialog__header {
        padding-left: 0.1rem;
        padding-right: 0.1rem;
    }
    .el-dialog__body {
        padding-top: 4px;
        padding-bottom: 20px;
        padding-left: 0;
        padding-right: 0;
        min-height: 15vh;
        max-height: 50vh;
        overflow: auto;
        max-height: 50vh;
        overflow-y: auto;
    }
}
.el-empty {
    margin: 10px 0;
    padding-block: 10px;
    .el-empty__image {
        // width: 0.8rem;
    }
}

._select {
    .el-input__wrapper {
        background: none !important;
        border: none !important;
        box-shadow: 0 0 0 0 !important;
        &:focus-visible {
            outline: none !important;
        }

        .el-input__inner {
            color: #fff !important;
            font-size: 0.14rem !important;
        }
    }
    .el-input {
        &:focus-visible {
            outline: none !important;
        }
    }
}
</style>
<style scoped lang="scss">
.home {
    padding: 0.54rem 0.13rem 2.7rem;
    position: relative;
    min-height: 100vh;
    background: url('../../assets/images/home/bg.png') no-repeat center center;
    background-size: 100% 100%;
    .video {
        width: calc(100% + 0.26rem);
        height: 100%;
        object-fit: cover;
        position: relative;
        left: -0.13rem;
    }
    .title {
        min-width: 1.7rem;
        height: 0.25rem;
        line-height: 0.25rem;
        background: url('../../assets/images/home/006.png') no-repeat center center;
        background-size: 100% 100%;
        position: absolute;
        top: -0.13rem;
        left: 50%;
        transform: translateX(-50%);
        font-weight: 500;
        font-size: 0.145rem;
        color: #ffcc00;
        text-align: center;
        padding: 0 0.1rem;
        word-break: keep-all;
    }
    .invite {
        margin-top: 0.37rem;
        width: 100%;
        background: url('../../assets/images/home/005.png') no-repeat center center;
        background-size: 100% 100%;
        position: relative;
        padding: 0.3rem 0 0.19rem 0.3rem;
        .content {
            font-weight: 500;
            font-size: 0.11rem;
            color: #ffffff;
            line-height: 1.5;
            .lib {
                display: flex;
                align-items: center;
                gap: 0.12rem;
                div {
                    font-weight: 500;
                    font-size: 0.1rem;
                    color: #000;
                    line-height: 0.15rem;
                    background: #7fff00;
                    border: 1px solid #009f25;
                    padding: 0.05rem 0.1rem;
                    border-radius: 0.08rem;
                }
            }
            p {
                margin-top: 0.06rem;
                font-weight: 500;
                font-size: 0.08rem;
                color: #9e9e9e;
                line-height: 1.1;
            }
        }
    }
    .stake {
        margin-top: 0.37rem;
        width: 100%;
        background: url('../../assets/images/home/101.png') no-repeat center center;
        background-size: 100% 100%;
        position: relative;
        padding: 0.28rem 0.3rem 0.22rem;
        .content {
            .balance {
                text-align: right;
                font-weight: 500;
                font-size: 0.1rem;
                color: #bfbfbf;
                line-height: 1;
                margin-bottom: 0.04rem;
                padding-right: 0.9rem;
            }
            .section {
                display: flex;
                align-items: center;
                gap: 0.1rem;
                .left {
                    position: relative;
                    flex: 1;
                    height: 0.33rem;
                    background: #fff;
                    border-radius: 0.05rem;
                    border: 1px solid #535353;
                    img {
                        position: absolute;
                        top: 50%;
                        left: 0.13rem;
                        height: 0.23rem;
                        transform: translateY(-50%);
                    }
                    input {
                        width: 100%;
                        height: 100%;
                        border: none !important;
                        outline: none !important;
                        background: none !important;
                        padding: 0 0.44rem 0 0.13rem;
                        font-size: 0.18rem;
                        font-weight: 600;
                        color: #000;
                        text-align: right;
                    }
                    span {
                        position: absolute;
                        top: 47%;
                        right: 0.06rem;
                        transform: translateY(-50%);
                        font-weight: 500;
                        font-size: 0.13rem;
                        color: #bfbfbf;
                    }
                }
                .right {
                    width: 0.75rem;
                    height: 0.33rem;
                    background: #fff;
                    border-radius: 0.05rem;
                    border: 1px solid #535353;

                    .days {
                        width: 100%;
                        height: 100%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 0.15rem;
                        color: #000;
                        font-weight: 600;
                        gap: 0.11rem;
                        &.disabled {
                            font-size: 0.13rem;
                            gap: 0.06rem;
                            color: #bfbfbf;
                        }
                        i {
                            color: #000;
                        }
                    }
                }
            }
            .amounts {
                margin: 0.15rem 0 0.13rem;
                display: flex;
                align-items: center;
                gap: 0.06rem;
                div {
                    flex: 1;
                    height: 0.22rem;
                    border-radius: 0.03rem;
                    border: 1px solid #009f25;
                    font-size: 0.1rem;
                    line-height: 0.2rem;
                    text-align: center;
                    background: #fff;
                    color: #3d3d3d;
                    transition: all 0.2s;
                    &.active {
                        background: #7fff00;
                    }
                }
            }
            button {
                width: 100%;
                height: 0.33rem;
                background: #7fff00;
                border-radius: 0.03rem;
                border: 1px solid #009f25;
                font-size: 0.15rem;
                color: #3d3d3d;
            }
            .tip {
                text-align: center;
                font-size: 0.11rem;
                color: #bfbfbf;
                line-height: 1;
                margin-top: 0.06rem;
            }
        }
    }
    .reward {
        margin-top: 0.37rem;
        width: 100%;
        background: url('../../assets/images/home/005.png') no-repeat center center;
        background-size: 100% 100%;
        position: relative;
        padding: 0.36rem 0.3rem 0.22rem;
        .content {
            font-weight: 500;
            font-size: 0.1rem;
            color: #ffffff;
            line-height: 1.8;
        }
        button {
            position: absolute;
            bottom: 0.28rem;
            right: 0.27rem;
            min-width: 1.1rem;
            height: 0.33rem;
            background: #7fff00;
            border-radius: 0.03rem;
            border: 1px solid #009f25;
            font-size: 0.15rem;
            color: #3d3d3d;
            font-weight: 500;
        }
    }
    .price {
        margin-top: 0.3rem;
        width: 100%;
        background: url('../../assets/images/home/204.png') no-repeat center center;
        background-size: 100% 100%;
        height: 0.4rem;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.1rem;

        font-weight: 500;
        font-size: 0.18rem;
        color: #7fff00;
        img {
            height: 0.25rem;
        }
    }
    .copyright {
        position: absolute;
        bottom: 0.3rem;
        left: 0;
        width: 100%;
        text-align: center;
        font-size: 0.12rem;
        color: #ffffff;
        line-height: 1.2;
    }
}
</style>
