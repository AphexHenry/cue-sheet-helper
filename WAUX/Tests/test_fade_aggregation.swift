// Test for fade aggregation logic in CueFileParsingService
// Run with: swiftc WAUX/Services/CueFileParsingService.swift test_fade_aggregation.swift -o test_fade_bin && ./test_fade_bin

import Foundation

struct FadeAggregationTestRunner {
    static func main() {
        let service = CueFileParsingService()
        
        print("\n" + String(repeating: "=", count: 80))
        print("🧪 FADE AGGREGATION TESTS")
        print(String(repeating: "=", count: 80))
        
        testSimpleChain(service: service)
        testChainWithDifferentCatalog(service: service)
        testMultipleSeparateChains(service: service)
        testMutedClipWithCrossFades(service: service)
        testMutedClipSameCatalog(service: service)
    }
    
    /// Test 1: Long chain of same-catalog events with cross fades
    /// Expected: 1 merged event from 01:00:08:01 to 01:00:57:03
    static func testSimpleChain(service: CueFileParsingService) {
        print("\n📋 TEST 1: Long chain of same-catalog events with cross fades")
        print(String(repeating: "-", count: 80))
        
        let lines = """
CHANNEL 	EVENT   	CLIP NAME                     	START TIME    	END TIME      	DURATION      	STATE
1       	1       	(fade in)                     	   01:00:08:01	   01:00:14:20	   00:00:06:19	Unmuted
1       	2       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-152.L	   01:00:14:20	   01:00:21:03	   00:00:06:08	Unmuted
1       	3       	(cross fade)                  	   01:00:21:03	   01:00:22:18	   00:00:01:15	Unmuted
1       	4       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-177.L	   01:00:22:18	   01:00:23:19	   00:00:01:01	Unmuted
1       	5       	(cross fade)                  	   01:00:23:19	   01:00:24:21	   00:00:01:02	Unmuted
1       	6       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-178.L	   01:00:24:21	   01:00:27:05	   00:00:02:09	Unmuted
1       	7       	(cross fade)                  	   01:00:27:05	   01:00:27:17	   00:00:00:12	Unmuted
1       	8       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-159.L	   01:00:27:17	   01:00:29:07	   00:00:01:15	Unmuted
1       	9       	(cross fade)                  	   01:00:29:07	   01:00:29:20	   00:00:00:13	Unmuted
1       	10      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-161.L	   01:00:29:20	   01:00:37:01	   00:00:07:06	Unmuted
1       	11      	(cross fade)                  	   01:00:37:01	   01:00:38:00	   00:00:00:24	Unmuted
1       	12      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-179.L	   01:00:38:00	   01:00:38:17	   00:00:00:17	Unmuted
1       	13      	(cross fade)                  	   01:00:38:17	   01:00:39:04	   00:00:00:12	Unmuted
1       	14      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-180.L	   01:00:39:04	   01:00:39:23	   00:00:00:19	Unmuted
1       	15      	(cross fade)                  	   01:00:39:23	   01:00:41:05	   00:00:01:07	Unmuted
1       	16      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-163.L	   01:00:41:05	   01:00:44:02	   00:00:02:22	Unmuted
1       	17      	(cross fade)                  	   01:00:44:02	   01:00:46:04	   00:00:02:02	Unmuted
1       	18      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-154.L	   01:00:46:04	   01:00:47:06	   00:00:01:02	Unmuted
1       	19      	(cross fade)                  	   01:00:47:06	   01:00:47:18	   00:00:00:12	Unmuted
1       	20      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-155.L	   01:00:47:18	   01:00:49:12	   00:00:01:19	Unmuted
1       	21      	(cross fade)                  	   01:00:49:12	   01:00:50:00	   00:00:00:13	Unmuted
1       	22      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-164.L	   01:00:50:00	   01:00:50:23	   00:00:00:23	Unmuted
1       	23      	(cross fade)                  	   01:00:50:23	   01:00:52:03	   00:00:01:05	Unmuted
1       	24      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-165.L	   01:00:52:03	   01:00:52:15	   00:00:00:12	Unmuted
1       	25      	(cross fade)                  	   01:00:52:15	   01:00:53:10	   00:00:00:20	Unmuted
1       	26      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-166.L	   01:00:53:10	   01:00:54:07	   00:00:00:22	Unmuted
1       	27      	(cross fade)                  	   01:00:54:07	   01:00:54:23	   00:00:00:16	Unmuted
1       	28      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-168.L	   01:00:54:23	   01:00:57:03	   00:00:02:05	Unmuted
""".components(separatedBy: "\n")
        
        let result = service.parseWithAllLayers(from: lines)
        
        print("\n📊 Results after Layer 2 (aggregateFadesWithClips):")
        print("   Expected: 1 event")
        print("   Got: \(result.layer2.count) events")
        
        if result.layer2.count == 1 {
            let event = result.layer2[0]
            print("\n   ✅ PASS: Got 1 event as expected")
            print("   Start: \(event.startTime) (expected: 01:00:08:01)")
            print("   End: \(event.endTime) (expected: 01:00:57:03)")
            print("   Catalog: \(event.catalogID)")
            
            if event.startTime == "01:00:08:01" && event.endTime == "01:00:57:03" {
                print("   ✅ PASS: Time range is correct!")
            } else {
                print("   ❌ FAIL: Time range is incorrect")
            }
        } else {
            print("\n   ❌ FAIL: Expected 1 event but got \(result.layer2.count)")
            for (i, event) in result.layer2.enumerated() {
                print("   Event \(i + 1): \(event.catalogID) from \(event.startTime) to \(event.endTime)")
            }
        }
    }
    
    /// Test 2: Chain interrupted by different catalog ID
    /// Expected: 3 events
    static func testChainWithDifferentCatalog(service: CueFileParsingService) {
        print("\n📋 TEST 2: Chain with different catalog ID in the middle")
        print(String(repeating: "-", count: 80))
        
        let lines = """
CHANNEL 	EVENT   	CLIP NAME                     	START TIME    	END TIME      	DURATION      	STATE
1       	1       	(fade in)                     	   01:00:08:01	   01:00:14:20	   00:00:06:19	Unmuted
1       	2       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-152.L	   01:00:14:20	   01:00:21:03	   00:00:06:08	Unmuted
1       	3       	(cross fade)                  	   01:00:21:03	   01:00:22:18	   00:00:01:15	Unmuted
1       	4       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-177.L	   01:00:22:18	   01:00:23:19	   00:00:01:01	Unmuted
1       	5       	(cross fade)                  	   01:00:23:19	   01:00:24:21	   00:00:01:02	Unmuted
1       	6       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-178.L	   01:00:24:21	   01:00:27:05	   00:00:02:09	Unmuted
1       	7       	(cross fade)                  	   01:00:27:05	   01:00:27:17	   00:00:00:12	Unmuted
1       	8       	MISS_25FPS_MX_DCP_STEREO_WIP_250721-159.L	   01:00:27:17	   01:00:29:07	   00:00:01:15	Unmuted
1       	9       	(cross fade)                  	   01:00:29:07	   01:00:29:20	   00:00:00:13	Unmuted
1       	10      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-161.L	   01:00:29:20	   01:00:37:01	   00:00:07:06	Unmuted
1       	11      	(cross fade)                  	   01:00:37:01	   01:00:38:00	   00:00:00:24	Unmuted
1       	12      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-179.L	   01:00:38:00	   01:00:38:17	   00:00:00:17	Unmuted
1       	13      	(cross fade)                  	   01:00:38:17	   01:00:39:04	   00:00:00:12	Unmuted
1       	14      	OTHER_FILE-163.L	   01:00:39:04	   01:00:39:23	   00:00:00:19	Unmuted
1       	15      	(cross fade)                  	   01:00:39:23	   01:00:41:05	   00:00:01:07	Unmuted
1       	16      	OTHER_FILE-163.L	   01:00:41:05	   01:00:44:02	   00:00:02:22	Unmuted
1       	17      	(cross fade)                  	   01:00:44:02	   01:00:46:04	   00:00:02:02	Unmuted
1       	18      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-154.L	   01:00:46:04	   01:00:47:06	   00:00:01:02	Unmuted
1       	19      	(cross fade)                  	   01:00:47:06	   01:00:47:18	   00:00:00:12	Unmuted
1       	20      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-155.L	   01:00:47:18	   01:00:49:12	   00:00:01:19	Unmuted
1       	21      	(cross fade)                  	   01:00:49:12	   01:00:50:00	   00:00:00:13	Unmuted
1       	22      	MISS_25FPS_MX_DCP_STEREO_WIP_250721-164.L	   01:00:50:00	   01:00:50:23	   00:00:00:23	Unmuted
""".components(separatedBy: "\n")
        
        let result = service.parseWithAllLayers(from: lines)
        
        print("\n📊 Results after Layer 2 (aggregateFadesWithClips):")
        print("   Expected: 3 events")
        print("   Got: \(result.layer2.count) events")
        
        if result.layer2.count == 3 {
            print("\n   ✅ PASS: Got 3 events as expected")
            
            let missEvents = result.layer2.filter { $0.catalogID == "MISS_25FPS_MX_DCP_STEREO_WIP_250721" }
            let otherEvents = result.layer2.filter { $0.catalogID == "OTHER_FILE" }
            
            print("\n   Event 1 (MISS_25FPS):")
            if let event = missEvents.first {
                print("      Start: \(event.startTime) (expected: 01:00:08:01)")
                print("      End: \(event.endTime) (expected: 01:00:39:04)")
                if event.startTime == "01:00:08:01" && event.endTime == "01:00:39:04" {
                    print("      ✅ PASS")
                } else {
                    print("      ❌ FAIL: Incorrect time range")
                }
            }
            
            print("\n   Event 2 (OTHER_FILE):")
            if let event = otherEvents.first {
                print("      Start: \(event.startTime) (expected: 01:00:38:17)")
                print("      End: \(event.endTime) (expected: 01:00:46:04)")
                if event.startTime == "01:00:38:17" && event.endTime == "01:00:46:04" {
                    print("      ✅ PASS")
                } else {
                    print("      ❌ FAIL: Incorrect time range")
                }
            }
            
            print("\n   Event 3 (MISS_25FPS):")
            if missEvents.count > 1 {
                let event = missEvents[1]
                print("      Start: \(event.startTime) (expected: 01:00:44:02)")
                print("      End: \(event.endTime) (expected: 01:00:50:23)")
                if event.startTime == "01:00:44:02" && event.endTime == "01:00:50:23" {
                    print("      ✅ PASS")
                } else {
                    print("      ❌ FAIL: Incorrect time range")
                }
            }
        } else {
            print("\n   ❌ FAIL: Expected 3 events but got \(result.layer2.count)")
            for (i, event) in result.layer2.enumerated() {
                print("   Event \(i + 1): \(event.catalogID) from \(event.startTime) to \(event.endTime)")
            }
        }
    }
    
    /// Test 3: Multiple separate chains
    static func testMultipleSeparateChains(service: CueFileParsingService) {
        print("\n📋 TEST 3: Multiple separate chains with fade out")
        print(String(repeating: "-", count: 80))
        
        let lines = """
CHANNEL 	EVENT   	CLIP NAME                     	START TIME    	END TIME      	DURATION      	STATE
1       	1       	(fade in)                     	   01:00:08:01	   01:00:10:00	   00:00:01:24	Unmuted
1       	2       	CAT_A-01.L	   01:00:10:00	   01:00:15:00	   00:00:05:00	Unmuted
1       	3       	(cross fade)                  	   01:00:15:00	   01:00:16:00	   00:00:01:00	Unmuted
1       	4       	CAT_A-02.L	   01:00:16:00	   01:00:20:00	   00:00:04:00	Unmuted
1       	5       	(fade out)                    	   01:00:20:00	   01:00:22:00	   00:00:02:00	Unmuted
1       	6       	(fade in)                     	   01:00:25:00	   01:00:27:00	   00:00:02:00	Unmuted
1       	7       	CAT_B-01.L	   01:00:27:00	   01:00:30:00	   00:00:03:00	Unmuted
1       	8       	(cross fade)                  	   01:00:30:00	   01:00:31:00	   00:00:01:00	Unmuted
1       	9       	CAT_B-02.L	   01:00:31:00	   01:00:35:00	   00:00:04:00	Unmuted
1       	10      	(fade out)                    	   01:00:35:00	   01:00:37:00	   00:00:02:00	Unmuted
""".components(separatedBy: "\n")
        
        let result = service.parseWithAllLayers(from: lines)
        
        print("\n📊 Results after Layer 2 (aggregateFadesWithClips):")
        print("   Expected: 2 events (one for CAT_A, one for CAT_B)")
        print("   Got: \(result.layer2.count) events")
        
        if result.layer2.count == 2 {
            print("\n   ✅ PASS: Got 2 events as expected")
            
            for (i, event) in result.layer2.enumerated() {
                print("\n   Event \(i + 1):")
                print("      Catalog: \(event.catalogID)")
                print("      Start: \(event.startTime)")
                print("      End: \(event.endTime)")
            }
            
            let catAEvent = result.layer2.first { $0.catalogID == "CAT_A" }
            let catBEvent = result.layer2.first { $0.catalogID == "CAT_B" }
            
            if let catA = catAEvent {
                if catA.startTime == "01:00:08:01" && catA.endTime == "01:00:22:00" {
                    print("\n   ✅ PASS: CAT_A has correct time range")
                } else {
                    print("\n   ❌ FAIL: CAT_A has incorrect time range")
                }
            }
            
            if let catB = catBEvent {
                if catB.startTime == "01:00:25:00" && catB.endTime == "01:00:37:00" {
                    print("\n   ✅ PASS: CAT_B has correct time range")
                } else {
                    print("\n   ❌ FAIL: CAT_B has incorrect time range")
                }
            }
        } else {
            print("\n   ❌ FAIL: Expected 2 events but got \(result.layer2.count)")
            for (i, event) in result.layer2.enumerated() {
                print("   Event \(i + 1): \(event.catalogID) from \(event.startTime) to \(event.endTime)")
            }
        }
    }
    
    /// Test 4: Muted clip with cross fades should convert cross fades to fade out/in
    /// Expected: 2 separate events (cross fade should not connect them)
    static func testMutedClipWithCrossFades(service: CueFileParsingService) {
        print("\n📋 TEST 4: Muted clip with adjacent cross fades")
        print(String(repeating: "-", count: 80))
        
        let lines = """
CHANNEL 	EVENT   	CLIP NAME                     	START TIME    	END TIME      	DURATION      	STATE
1       	136     	MISS_MXstem_DCP_stereo-185.L  	   03:01:51:12	   03:01:53:03	   00:00:01:16	Unmuted
1       	137     	(cross fade)                  	   03:01:53:03	   03:01:53:08	   00:00:00:04	Unmuted
1       	138     	MISS_MXstem_DCP_stereo-286.L  	   03:01:53:08	   03:01:53:20	   00:00:00:11	Muted
1       	139     	(cross fade)                  	   03:01:53:20	   03:01:54:00	   00:00:00:05	Unmuted
1       	140     	UPM_3M35_4_Intruders_Backing_Vocals_Only_Kampe_1827883-05.L	   03:06:21:18	   03:06:55:22	   00:00:34:04	Unmuted
""".components(separatedBy: "\n")
        
        let result = service.parseWithAllLayers(from: lines)
        
        print("\n📊 Results after Layer 2 (aggregateFadesWithClips):")
        print("   Expected: 2 separate events (muted clip breaks the cross fade)")
        print("   Got: \(result.layer2.count) events")
        
        if result.layer2.count == 2 {
            print("\n   ✅ PASS: Got 2 events as expected")
            
            let missEvent = result.layer2.first { $0.catalogID == "MISS_MXstem_DCP_stereo" }
            let upmEvent = result.layer2.first { $0.catalogID.starts(with: "UPM_3") }
            
            print("\n   Event 1 (MISS_MXstem_DCP_stereo):")
            if let event = missEvent {
                print("      Start: \(event.startTime) (expected: 03:01:51:12)")
                print("      End: \(event.endTime) (expected: 03:01:53:08)")
                if event.startTime == "03:01:51:12" && event.endTime == "03:01:53:08" {
                    print("      ✅ PASS: Time range is correct!")
                } else {
                    print("      ❌ FAIL: Time range is incorrect")
                }
            } else {
                print("      ❌ FAIL: MISS event not found")
            }
            
            print("\n   Event 2 (UPM_3M35_4...):")
            if let event = upmEvent {
                print("      Start: \(event.startTime) (expected: 03:06:21:18)")
                print("      End: \(event.endTime) (expected: 03:06:55:22)")
                if event.startTime == "03:06:21:18" && event.endTime == "03:06:55:22" {
                    print("      ✅ PASS: Time range is correct!")
                } else {
                    print("      ❌ FAIL: Time range is incorrect")
                }
            } else {
                print("      ❌ FAIL: UPM event not found")
            }
        } else {
            print("\n   ❌ FAIL: Expected 2 events but got \(result.layer2.count)")
            for (i, event) in result.layer2.enumerated() {
                print("   Event \(i + 1): \(event.catalogID) from \(event.startTime) to \(event.endTime)")
            }
        }
    }
    
    /// Test 5: Muted clip with same catalog on both sides - CRITICAL TEST
    /// This is the real problem: if catalog is same, it would incorrectly merge
    static func testMutedClipSameCatalog(service: CueFileParsingService) {
        print("\n📋 TEST 5: Muted clip with same catalog on both sides (CRITICAL)")
        print(String(repeating: "-", count: 80))
        
        let lines = """
CHANNEL 	EVENT   	CLIP NAME                     	START TIME    	END TIME      	DURATION      	STATE
1       	1       	MISS_MXstem_DCP_stereo-185.L  	   03:01:51:12	   03:01:53:03	   00:00:01:16	Unmuted
1       	2       	(cross fade)                  	   03:01:53:03	   03:01:53:08	   00:00:00:04	Unmuted
1       	3       	MISS_MXstem_DCP_stereo-286.L  	   03:01:53:08	   03:01:53:20	   00:00:00:11	Muted
1       	4       	(cross fade)                  	   03:01:53:20	   03:01:54:00	   00:00:00:05	Unmuted
1       	5       	MISS_MXstem_DCP_stereo-187.L  	   03:06:21:18	   03:06:55:22	   00:00:34:04	Unmuted
""".components(separatedBy: "\n")
        
        let result = service.parseWithAllLayers(from: lines)
        
        print("\n📊 Results after Layer 2 (aggregateFadesWithClips):")
        print("   Expected: 2 separate events (muted clip breaks continuity)")
        print("   Got: \(result.layer2.count) events")
        
        let missEvents = result.layer2.filter { $0.catalogID == "MISS_MXstem_DCP_stereo" }
        
        if missEvents.count == 2 {
            print("\n   ✅ PASS: Got 2 separate MISS events as expected")
            
            print("\n   Event 1:")
            let event1 = missEvents[0]
            print("      Start: \(event1.startTime) (expected: 03:01:51:12)")
            print("      End: \(event1.endTime) (expected: 03:01:53:08)")
            if event1.startTime == "03:01:51:12" && event1.endTime == "03:01:53:08" {
                print("      ✅ PASS: Time range is correct!")
            } else {
                print("      ❌ FAIL: Time range is incorrect")
            }
            
            print("\n   Event 2:")
            let event2 = missEvents[1]
            print("      Start: \(event2.startTime) (expected: 03:06:21:18)")
            print("      End: \(event2.endTime) (expected: 03:06:55:22)")
            if event2.startTime == "03:06:21:18" && event2.endTime == "03:06:55:22" {
                print("      ✅ PASS: Time range is correct!")
            } else {
                print("      ❌ FAIL: Time range is incorrect")
            }
        } else if missEvents.count == 1 {
            print("\n   ❌ FAIL: Got 1 merged event - muted clip did not break the chain!")
            let event = missEvents[0]
            print("   Incorrectly merged event:")
            print("      Start: \(event.startTime)")
            print("      End: \(event.endTime)")
            print("   This is THE BUG - cross fades should have been converted to fade out/in")
        } else {
            print("\n   ❌ FAIL: Expected 2 events but got \(missEvents.count)")
            for (i, event) in missEvents.enumerated() {
                print("   Event \(i + 1): from \(event.startTime) to \(event.endTime)")
            }
        }
    }
}

