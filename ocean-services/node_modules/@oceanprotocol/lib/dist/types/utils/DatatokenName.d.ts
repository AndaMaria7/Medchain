/**
 * This function generates a datatoken name and symbol from a given word list.
 * @param {Object} [wordList] - An object containing an array of nouns and adjectives.
 * @param {string[]} [wordList.nouns] - An array of nouns.
 * @param {string[]} [wordList.adjectives] - An array of adjectives.
 * @returns {Object} Returns an object containing the generated name and symbol. Produces e.g. "Endemic Jellyfish Token" & "ENDJEL-45"
 */
export declare function generateDtName(wordList?: {
    nouns: string[];
    adjectives: string[];
}): {
    name: string;
    symbol: string;
};
