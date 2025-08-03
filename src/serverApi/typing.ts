export type IHomedata = {
    user: string;
    inviter: string;
};
export type IParticipate = {
    hash: string;
    user: string;
    inviter: string;
};
export type IDeposit = {
    hash: string;
    user: string;
    depositnum: number;
};
export type IUpgrade = {
    hash: string;
    user: string;
};
export type IClaim = {
    hash: string;
    user: string;
};
export type IClaimStatus = {
    index: number;
    hash: string;
};
export type ILevels = {
    user: string;
    level: string;
};
export type INewuser = {
    user: string;
    newuser: string;
};
