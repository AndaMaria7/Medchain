/**
 * Generates a valid DID
 * @param {string} nftAddress - The NFT address
 * @param {number} chainId - The chain ID
 * @returns {string} - The DID
 */
export declare function generateDid(nftAddress: string, chainId: number): string;
/**
 * Returns the SHA256 hash of the input data
 * @param {any} data - The input data
 * @returns {string} - The SHA256 hash of the input data
 */
export declare function getHash(data: any): string;
