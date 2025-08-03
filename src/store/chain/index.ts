import { defineStore } from 'pinia';
import { ethers } from 'ethers';
import { ElMessage } from 'element-plus';
import 'element-plus/es/components/message/style/css';
import abi_erc20 from './abi_erc20';
import abi_erc721 from './abi_erc721.json';
import abi_mine from './mine-abi.json';
import { markRaw } from 'vue';
import abi_multicall from './multicall.json';

const infra_key = 'https://node1.pegorpc.com';

export const sleep = (time = 5000) => {
    return new Promise(resolve => setTimeout(resolve, time));
};

export const getProvider = () => {
    if (!window.ethereum) {
        return new (ethers as any).providers.JsonRpcProvider(infra_key);
    } else {
        return new (ethers as any).providers.Web3Provider(window.ethereum, 'any');
    }
};
export const useBlockChain = defineStore('block-chain-store', {
    state() {
        return {
            // web3
            provider: undefined,
            account: '',
            chainId: 0,
            signer: undefined,
            token: '',

            // base
            contract_address: {
                56: {
                    usdtContract: '',
                    mineContract: '',
                    multicall: '0x38ce767d81de3940cfa5020b55af1a400ed4f657',
                },
                97: {
                    usdtContract: '0x0FB3c077479113dF18f9f51Dc282b09bB0461000',
                    mineContract: '0xFDE1948d1bDEDcCf4BD6538Da6Fae1b1F0Fc48b5',
                    multicall: '0x7Ff1b4B31afdBC1E76B5edeB73225685fe477a72',
                },
            },
            firstAddress: {
                56: '',
                97: '0x9Ee20a74588A1D89e028a2be4CCF842ac9352111',
            },
            lange: 'zh',
            link: {
                tg: '',
                tw: '',
                web: '',
                web_url: `${window.location.origin}/#`,
            },
            inviter: '',

            // process
            timer: null,
            show_process: false,
            process_time: 20,
        };
    },

    actions: {
        async init_blockChain() {
            let provider = getProvider();
            this.provider = markRaw(provider);

            if (!window.ethereum) {
                ElMessage({
                    showClose: true,
                    message: 'Metamask未安裝',
                    type: 'error',
                    duration: 2000,
                });
                return;
            }
        },

        async connectWallet() {
            try {
                const _chainId = Number((await this.provider.getNetwork()).chainId);
                let accounts = await this.provider.send('eth_requestAccounts', []);
                this.signer = this.provider.getSigner();
                if (![56, 97].includes(_chainId)) {
                    ElMessage.error({
                        message: '請切換到BSC網絡',
                        duration: 7000,
                    });
                    return;
                }

                // await this.signer.signMessage(`Auth ZhaoYun at:${Date.now()}`);
                this.account = accounts[0].toLowerCase();
                // this.account = '0xec3CfED9CA0CD7BD9D280f0e804431B82C64e222';
                this.chainId = Number((await this.provider.getNetwork()).chainId);
            } catch (e: any) {
                ElMessage.error(e?.message ?? 'error');
            }
        },

        async disconnect() {
            try {
                var res = await window.ethereum.request({
                    method: 'wallet_revokePermissions',
                    params: [
                        {
                            eth_accounts: {},
                        },
                    ],
                });
                this.account = '';
                this.chainId = 0;
                console.log('连接已断开', res);
            } catch (e: any) {
                ElMessage.error(e?.message ?? 'error');
            }
        },

        setLange(lange: string) {
            this.lange = lange;
        },
        setInviter(address: string) {
            this.inviter = address.toLowerCase();
            window.sessionStorage.setItem('inviter', this.inviter);
        },

        getTokenContract() {
            return new ethers.Contract(this.contract_address[this.chainId].tokenContract, abi_erc20, this.signer);
        },

        getMineContract() {
            return new ethers.Contract(this.contract_address[this.chainId].mineContract, abi_mine.abi, this.signer);
        },
        getMulticallContract() {
            return new ethers.Contract(this.contract_address[this.chainId].multicall, abi_multicall, this.provider);
        },

        async awaitTransactionMined(hash) {
            try {
                await sleep(15000);
                const res = await this.provider.getTransactionReceipt(hash);
                if (res.status) {
                    return true;
                } else {
                    return false;
                }
            } catch (e) {
                throw e;
            }
        },

        async approve(contract_address, token_address, amount) {
            try {
                const token = new ethers.Contract(token_address, abi_erc20, this.signer);
                const transferTx = await token.approve(contract_address, amount);
                const receipt = await transferTx.wait();
                return receipt.status;
            } catch (e: any) {
                throw e;
            }
        },
        async approveNft(contract_address, nft_address) {
            try {
                const contract = new ethers.Contract(nft_address, abi_erc721, this.signer);
                const transferTx = await contract.setApprovalForAll(contract_address, true);
                const receipt = await transferTx.wait();
                return receipt.status;
            } catch (e: any) {
                throw e;
            }
        },

        async getAllowance(token_address, contract_address, user?: string) {
            const token = new ethers.Contract(token_address, abi_erc20, this.signer);
            const allowance = await token.allowance(user || this.account, contract_address);
            return allowance.toString();
        },

        async getNftAllowance(nft_address, contract_address, user?: string) {
            const contract = new ethers.Contract(nft_address, abi_erc721, this.signer);
            const isApprove = await contract.isApprovedForAll(user || this.account, contract_address);
            return isApprove;
        },

        async getNftBalance(nft_address: string, user?: string) {
            // const token = new ethers.Contract(nft_address, abi_nft, this.signer);
            // let balance = await token.balanceOf(user || this.account);
            // return balance.toString();
        },

        async getBalance(token_address: string, user?: string) {
            let balance = 0;
            if (token_address.toLowerCase() === '0x0000000000000000000000000000000000000000') {
                balance = await this.provider.getBalance(user || this.account);
            } else {
                const token = new ethers.Contract(token_address, abi_erc20, this.signer);
                balance = await token.balanceOf(user || this.account);
            }
            return balance.toString();
        },

        async getTokenDecimals(token_address) {
            const token = new ethers.Contract(token_address, abi_erc20, this.signer);
            console.log(await token.decimals());
            return await token.decimals();
        },

        async sendTransaction(toAddress, amount) {
            try {
                const signer = this.provider.getSigner(this.account);
                const tx = {
                    to: toAddress,
                    value: amount,
                };
                const signedTx = await signer.sendTransaction(tx);
                this.handProcess('open');
                const result = await signedTx.wait();
                return result;
            } catch (error) {
                throw error;
            }
        },

        async sendUsdtTransaction(toAddress, amount) {
            try {
                const signer = this.provider.getSigner(this.account);
                const usdtContract = new ethers.Contract(this.contract_address[this.chainId].usdt, abi_erc20, signer);
                const transferTx = await usdtContract.transfer(toAddress, amount);
                this.handProcess('open');
                const result = await transferTx.wait();
                return result;
            } catch (error) {
                throw error;
            }
        },

        handProcess(type: 'open' | 'close', callback?: () => void, time: number = 20) {
            this.show_process = type === 'open' ? true : false;
            this.process_time = type === 'open' ? time : 0;
            clearInterval(this.timer);
            if (type === 'open') {
                this.timer = setInterval(() => {
                    this.process_time -= 1;
                    if (this.process_time <= 0) {
                        clearInterval(this.timer);
                        this.process_time = 0;
                        if (callback) {
                            callback();
                        }
                    }
                }, 1000);
            }
        },
    },
});
