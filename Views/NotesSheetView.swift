import SwiftUI

struct NotesSheetView: View {
    let text: String
    let offset: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // The image is square (1:1). Scale to fill width.
            let imgSize = w

            ZStack {
                // Layer 1: Hands + blank paper image
                Image("PracticeNotesFrame")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imgSize)

                // Layer 2: Scrolling text clipped to the paper area
                // Paper region within the image:
                //   - centered horizontally, ~70% of image width
                //   - top: ~6% from image top
                //   - bottom: ~24% from image bottom (hands grip)
                //   - left/right: ~15% inset from edges
                teleprompterText
                    .frame(
                        width: imgSize * 0.58,
                        height: imgSize * 0.62
                    )
                    .clipped()
                    .offset(y: -imgSize * 0.06)
            }
            .frame(width: w, height: h, alignment: .top)
        }
    }

    private var teleprompterText: some View {
        GeometryReader { _ in
            Text(text)
                .font(SUFont.teleprompter())
                .foregroundStyle(SUColor.ink)
                .lineSpacing(10)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 80)
                .offset(y: -offset)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .clipped()
    }
}
