import axiosService from '@/utils/axios';
import { IParticipate, IDeposit, IClaim, IUpgrade, IHomedata, IClaimStatus, ILevels, INewuser } from './typing';
class Server {
    static meta = {
        baseUrl: 'https://www.pegoluckystar.com',
    };

    public static claimlk<T>(user: string): Promise<T> {
        return axiosService({
            url: `${this.meta.baseUrl}/claimlk`,
            method: 'post',
            data: {
                user,
            },
        });
    }
    public static getuserlk<T>(user: string): Promise<T> {
        return axiosService({
            url: `${this.meta.baseUrl}/getuserlk`,
            method: 'get',
            params: {
                user,
            },
        });
    }
    public static getfreelkminted<T>(): Promise<T> {
        return axiosService({
            url: `${this.meta.baseUrl}/getfreelkminted`,
            method: 'get',
        });
    }
    public static async getmanager<T>(user: string): Promise<boolean> {
        try {
            // const result = await axiosService({
            //     url: `${this.meta.baseUrl}/getmanager`,
            //     method: 'get',
            // });
            const result = ['0xA4Fe9B7353f2F6FAf370275F467Ff6E19d3958bc', '0x72C2d51Fe90109f9293aC966cC12a5FEB01E66ad', '0x5e8AF056BD20066B494c22f1faDbDEE8380f8777', '0xeF6191A5C8e983dA45DAC2A787d49fE3f2B6D54e', '0x59a8082bC047de76209ca00d2E2C1856aAf791B5'];
            return result.map(ele => ele.toLowerCase()).includes(user.toLowerCase());
        } catch (e) {
            return false;
        }
    }
}

export default Server;
