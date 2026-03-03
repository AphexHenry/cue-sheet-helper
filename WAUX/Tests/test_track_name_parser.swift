// Track name parsing tests
// Run standalone with:
// swiftc -D TRACK_NAME_PARSER_STANDALONE WAUX/Services/TrackNameParser.swift WAUX/Tests/test_track_name_parser.swift -o test_track_name_parser && ./test_track_name_parser

import Foundation

struct TrackNameParserTestRunner {
    static func main() {
        let parseCases: [(input: String, expectedCatalogID: String, expectedTitle: String)] = [
            (
                "UPM_MAT103_7_Champions_Instrumental_Martin_8168-04.L",
                "UPM_MAT103_7",
                "Champions_Instrumental_Martin_8168"
            ),
            (
                "_UPRIGHT_GMPM_197_041_Storyteller_(Strings_Only)-13.A1",
                "_UPRIGHT_GMPM_197_041",
                "Storyteller_(Strings_Only)"
            ),
            (
                "MISS_25FPS_MX_DCP_STEREO_WIP_250721-152.L",
                "MISS_25",
                "FPS_MX_DCP_STEREO_WIP_250721"
            ),
            (
                "Simple Name.L",
                "",
                "Simple Name"
            ),
            (
                "(cross fade)",
                "CROSS_FADE",
                ""
            ),
            (
                "CROSSROADS_OF_UNCERTAINTY_(A)ZAC_JORDAN(PRS)_The_Scoring_House_TSH_289_002-19.R",
                "TSH_289_002-19",
                "CROSSROADS_OF_UNCERTAINTY_(A)ZAC_JORDAN(PRS)_The_Scoring_House"
            ),
            (
                "CZOLOWKA-01.L",
                "",
                "CZOLOWKA"
            ),
            (
                "UPRIGHT_2FM_035_015_Cold_Shadows(Synth_only)-02.L",
                "UPRIGHT_2FM_035_015",
                "Cold_Shadows(Synth_only)"
            ),
            (
                "UPRIGHT_4EM_109_009_Contrary_Notions(Main)",
                "UPRIGHT_4EM_109_009",
                "Contrary_Notions(Main)"
            )
        ]

        print("\n🧪 Testing TrackNameParser.parse(input) => catalogID + title")
        runParseCases(parseCases)
        runSkipExtractionCase()
    }

    private static func runParseCases(_ cases: [(input: String, expectedCatalogID: String, expectedTitle: String)]) {
        var failures = 0

        for testCase in cases {
            let parsed = TrackNameParser.parse(testCase.input)
            let passedCatalog = parsed.catalogID == testCase.expectedCatalogID
            let passedTitle = parsed.title == testCase.expectedTitle
            let passed = passedCatalog && passedTitle

            if passed {
                print("✅ '\(testCase.input)'")
            } else {
                failures += 1
                print("❌ '\(testCase.input)'")
                print("   Expected catalogID: '\(testCase.expectedCatalogID)'")
                print("   Got catalogID:      '\(parsed.catalogID)'")
                print("   Expected title:     '\(testCase.expectedTitle)'")
                print("   Got title:          '\(parsed.title)'")
            }
        }

        if failures == 0 {
            print("\n✅ All parse cases passed")
        } else {
            print("\n❌ \(failures) parse case(s) failed")
            Foundation.exit(1)
        }
    }

    private static func runSkipExtractionCase() {
        let input = "UPM_MAT103_7_Champions_Instrumental_Martin_8168-04.L"
        let parsed = TrackNameParser.parse(input, skipCatalogExtraction: true)
        let expectedCatalog = ""
        let expectedTitle = "UPM_MAT103_7_Champions_Instrumental_Martin_8168"

        let passed = parsed.catalogID == expectedCatalog && parsed.title == expectedTitle
        if passed {
            print("✅ skipCatalogExtraction applies empty-title fallback")
        } else {
            print("❌ skipCatalogExtraction test failed")
            print("   Expected catalogID: '\(expectedCatalog)'")
            print("   Got catalogID:      '\(parsed.catalogID)'")
            print("   Expected title:     '\(expectedTitle)'")
            print("   Got title:          '\(parsed.title)'")
            Foundation.exit(1)
        }
    }
}

#if TRACK_NAME_PARSER_STANDALONE
@main
struct TrackNameParserStandaloneMain {
    static func main() {
        TrackNameParserTestRunner.main()
    }
}
#endif
