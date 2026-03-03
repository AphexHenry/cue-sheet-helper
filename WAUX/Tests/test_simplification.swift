// This test file runs the actual CueFileParsingService tests
// Run with: swiftc WAUX/Services/TrackNameParser.swift WAUX/Services/CueFileParsingService.swift WAUX/Tests/test_simplification.swift -o test_bin && ./test_bin
// Or use the built-in testSimplification() method from within the service

import Foundation

struct TestRunner {
    static func main() {
        let testCases = [
            ("UPM_LQC71_15_Mogadishu_Drone_Instrumental_Huntley_McNeil-Poly.L", "UPM_LQC71_15"),
            ("_UPRIGHT_GMPM_197_041_Storyteller_(Strings_Only)-13.A1", "_UPRIGHT_GMPM_197_041"),
            ("Baptiste Bohelay - Don't Look Back 2-01.L", "Baptiste Bohelay - Don't Look Back 2"),
            ("TEST_ABC123_456_Some_Title.R", "TEST_ABC123_456"),
            ("Simple Name.L", "Simple Name"),
            ("No_Numbers_Here.A1", "No_Numbers_Here"),
            ("ICON_74_2_Follower_Butler_Drones.1-03.L", "ICON_74_2"),
            ("ICON_74_2_Follower_Butler_Drones-22.L", "ICON_74_2"),
            ("UPM_NTP504_3_Take_My_Hand_Vocal_Lead_Gregory_Wilde_2127302-22.L", "UPM_NTP504_3")
        ]
        
        print("\n🧪 Testing getSimplifiedName:")
        let service = CueFileParsingService()
        for (input, expected) in testCases {
            let result = service.getSimplifiedName(input)
            let passed = result == expected
            let icon = passed ? "✅" : "❌"
            print("\(icon) Input: '\(input)'")
            print("   Expected: '\(expected)'")
            print("   Got:      '\(result)'")
            if !passed {
                print("   ⚠️ MISMATCH!")
            }
        }
    }
}
