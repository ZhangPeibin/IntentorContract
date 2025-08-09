
import * as path from "path";
import * as fs from "fs";
export async function getQuoter(chainId: number): Promise<string> {
    const quoterConfigPath = path.resolve(__dirname, "../../config/quoter.json");
    if (!fs.existsSync(quoterConfigPath)) {
        throw new Error(`❌ Quoter config file not found: ${quoterConfigPath}`);
    }
    const quoterConfig = JSON.parse(fs.readFileSync(quoterConfigPath, "utf-8"));
    const quoter = quoterConfig[Number(chainId).toString()];
    if (!quoter) {
        throw new Error(`❌ Quoter not found for chainId: ${chainId}`);
    }
    return quoter.quoter;
}


