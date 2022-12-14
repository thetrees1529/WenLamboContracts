    const addr = "0x1dAc74Ab578D39b0d3BCe7FD86b0923eF6d881a9"
    const gar="0x685d42fE7dB41431019bCff7E70AecD9Af90Fe12"
    const en = "0x371f50796359D0B6CbDdaACbB0d45ff3BB082C52"
const chain = "https://api.harmony.one"
const {ethers} = hre
const chunkSize = 1


async function main() {
    const old = new ethers.Contract(gar, require("../artifacts/contracts/Legacy/GarageManager.sol/IGarageManager.json").abi,new ethers.providers.JsonRpcProvider(chain))
    const earn = await ethers.getContractAt("Earn", en)
    const garage = await ethers.getContractAt("GarageMigrator", addr)
    const tokenIds = Array.from(Array(10000).keys())

    const chunks = []

    for(let i = 0; i < Math.ceil(tokenIds.length / chunkSize); i ++) {
        chunks.push(tokenIds.slice(i, i + chunkSize))
    }

    for(let i = 0; i < chunks.length; i ++) { 

        const ids = chunks[i]
        console.log(ids)

        let attributes = await Promise.all(ids.map(async id => await old.getTokenAttributes(id)))

        const stages = await earn.getStages()

        inputs = attributes.map((item,index) => {

            let data = {
                inLocation: false,
                newLocation: {
                    stage: 0,
                    substage: 0
                },
                locked: 0,
                claimable: 0
            }

            let score =
            item.pitCrew+ // 0 or 1
            item.crewChief+ // 0 -> 3
            item.mechanic+ // 0 -> 3
            item.gasman+ // 0 -> 3
            item.tireChanger;

            while(score > stages[data.newLocation.stage].substages.length) {
                score -= stages[data.newLocation.stage].substages.length;
                data.newLocation.stage ++;
            }

            if(score > 0) {
                data.newLocation.substage += score - 1;
                data.inLocation = true;
            }

            data.claimable = item.unlocked;
            data.locked = item.locked;

            return {
                tokenId: ids[index],
                data
            }
        })

        console.log("now check these: \n",JSON.stringify(inputs))
        let succ = false
        while(!succ) {
            try {
                await (await garage.migrate(inputs)).wait()
                succ = true
            }catch{}
        }
    }
}

main()