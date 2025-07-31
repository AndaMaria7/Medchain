export interface DispenserCreationParams {
    dispenserAddress: string;
    maxTokens: string;
    maxBalance: string;
    withMint?: boolean;
    allowedSwapper?: string;
}
export interface DispenserToken {
    active: boolean;
    owner: string;
    maxTokens: string;
    maxBalance: string;
    balance: string;
    isMinter: boolean;
    allowedSwapper: string;
}
