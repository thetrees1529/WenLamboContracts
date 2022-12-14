const { ethers } = hre

module.exports = {
    fujiMuscle: {
        burnRatio: [1,100],
        nft: "0x7fe8cb8dC1a191Ab8912B5476EE46c778d2D8B08",
        tokenAddr: "0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623",
        lockDelay: 60,
        lockPeriod: 120,
        lockRatio: [7,10],
        interest: [1,31540000],
        baseEarn: 11574074000000,
        mintCap: "218500000000000000000000000",
        stages: [["Mechanic", [["Mechanic Upgrade",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","1000000000000000000000"]], "23148148000000"]]],["Stage 1", [["Intake", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","80000000000000000000"]], "34722222000000"],["Cams", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","100000000000000000000"]], "46296296000000"],["Headers", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","120000000000000000000"]], "57870370000000"],["Converter", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","140000000000000000000"]], "69444444000000"]]],["Stage 2", [["Tuner Kit", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","160000000000000000000"]], "81018518000000"],["Injectors", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","180000000000000000000"]], "104166666000000"],["NOS", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","200000000000000000000"]], "127314814000000"],["Trans Brake", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","220000000000000000000"]], "150462962000000"]]],["Stage 3", [["Race Slicks", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","240000000000000000000"]], "196759258000000"],["Calipers", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","280000000000000000000"]], "243055554000000"],["Roll Cage", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","320000000000000000000"]], "289351850000000"],["Exhaust", [["0x3B39dc57a167bFa8b90e4064c7b3A6c2a164d623","360000000000000000000"]], "335648146000000"]]]]
    },
    fujiLambo: {
        burnRatio: [1,100],
        nft: "0xddfee5d523708799FcDd63B736bb95aE9546bF68",
        tokenAddr: "0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68",
        lockDelay: 100000,
        lockPeriod: 100000,
        lockRatio: [7,10],
        interest: [1,31540000],
        baseEarn: 11574074000000,
        mintCap: ethers.constants.MaxUint256,
        stages:[["Pit Crew", [["Pit Crew Upgrade",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","30000000000000000000"]], "23148148000000"]]],

        ["Tier 1", [["Crew Chief Tier 1",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","100000000000000000000"]], "34722222000000"],
        ["Mechanic Tier 1",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","100000000000000000000"]], "46296296000000"],
        ["Gas Man Tier 1",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","100000000000000000000"]], "57870370000000"],
        ["Tire Changer Tier 1",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","100000000000000000000"]], "69444444000000"]
        ]],
        
        ["Tier 2", [["Crew Chief Tier 2",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","180000000000000000000"]], "92592592000000"],
        ["Mechanic Tier 2",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","180000000000000000000"]], "115740740000000"],
        ["Gas Man Tier 2",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","180000000000000000000"]], "138888888000000"],
        ["Tire Changer Tier 2",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","180000000000000000000"]], "162037036000000"]
        ]],
        
        ["Tier 3", [["Crew Chief Tier 3",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","320000000000000000000"]], "208333332000000"],
        ["Mechanic Tier 3",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","320000000000000000000"]], "254629628000000"],
        ["Gas Man Tier 3",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","320000000000000000000"]], "300925924000000"],
        ["Tire Changer Tier 3",[["0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68","320000000000000000000"]], "347222220000000"]
        ]],
        
        
        ]
        
        
        
        
        
        
    }
}