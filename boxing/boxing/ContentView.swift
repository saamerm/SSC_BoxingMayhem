//
//  ContentView.swift
//  boxing
//
//  Created by Saamer Mansoor on 4/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameService = GameService(difficulty: 1.0)
    @State private var bgLoc = CGPoint(x: Device.width / 2, y: Device.height / 2)
    @State private var bgPosX = Device.width / 2 * 1.1
    @State private var goToLeft = false
    @State private var playScale = 1.0
    @State var isAboutPresented = false
    @State private var playerOffsetY: CGFloat = Device.height
    @State private var opponentOffsetY: CGFloat = Device.height

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(bgLoc: $bgLoc, bgPosX: $bgPosX, goToLeft: $goToLeft)

                VStack {}
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .background(Color.black.opacity(0.3))

                Image("fight-pose-player")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 360)
                    .position(x: Device.width - 240, y: Device.height - 120)
                    .offset(y: playerOffsetY) // Add offset for animation
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: playerOffsetY)

                Image("fight-pose-opponent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 330)
                    .position(x: 100, y: Device.height - 120)
                    .offset(y: opponentOffsetY) // Add offset for animation
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: opponentOffsetY)

                VStack(spacing: 24) {
                    Logo()
                    ButtonStack(
                        isGamePlayed: $gameService.isGamePlayed,
                        isAboutPresented: $isAboutPresented,
                        playScale: $playScale,
                        gameState: $gameService.gameState,
                        showingTutorial: $gameService.isShowingTutorial
                    )
                }
            }
        }
        .onAppear {
            AudioManager.shared.playSound("bgm")
            AudioManager.shared.setVolume(0.3, for: "bgm")

            // Trigger the animations with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                playerOffsetY = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                opponentOffsetY = 0
            }
        }
        .sheet(isPresented: $gameService.isGamePlayed) {
            Game(isGamePlayed: $gameService.isGamePlayed)
                .environmentObject(gameService)
        }
        .sheet(isPresented: $isAboutPresented) {
            AboutView(isAboutPresented: $isAboutPresented)
        }

        .sheet(isPresented: $gameService.isShowingTutorial) {
            TutorialView()
                .environmentObject(gameService)
        }

#if !os(macOS)
        .navigationViewStyle(StackNavigationViewStyle())
#else
        .navigationViewStyle(.columns)
#endif
    }
}

struct BackgroundView: View {
    @Binding var bgLoc: CGPoint
    @Binding var bgPosX: CGFloat
    @Binding var goToLeft: Bool

    var body: some View {
        Image("background")
            .resizable()
            .frame(width: Device.width * 1.1, height: Device.height * 1.1)
            .position(bgLoc)
            .background(Color.blue.secondary)
            .ignoresSafeArea(.all)
            .onAppear {
                startBackgroundAnimation()
                setupBackgroundTimer()
            }
    }

    private func startBackgroundAnimation() {
        withAnimation(Animation.linear(duration: 15).repeatForever()) {
            bgLoc = CGPoint(x: bgPosX, y: Device.height / 2)
        }
    }

    private func setupBackgroundTimer() {
        let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

        let _ = timer.sink { _ in
            if goToLeft {
                withAnimation {
                    bgPosX = Device.width / 2 / 1.1
                }
            }
        }
    }
}

struct Logo: View {
    var body: some View {
        Image("logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 260)
    }
}

struct ButtonStack: View {
    @Binding var isGamePlayed: Bool
    @Binding var isAboutPresented: Bool
    @Binding var playScale: Double
    @Binding var gameState: String
    @Binding var showingTutorial: Bool

    var body: some View {
        VStack(spacing: 4) {
            PlayButton(isGamePlayed: $isGamePlayed, playScale: $playScale, gameState: $gameState)
            AboutButton(isAboutPresented: $isAboutPresented)

            Button(action: {
                showingTutorial = true
            }) {
                Image("tutorial")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .frame(width: 180, height: 60)
        }
    }
}

struct PlayButton: View {
    @Binding var isGamePlayed: Bool
    @Binding var playScale: Double
    @Binding var gameState: String
    var body: some View {
        Button(action: {
            isGamePlayed = true
            gameState = "countdown"
        }) {
            Image("play")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .frame(width: 180, height: 60)
    }
}

struct AboutButton: View {
    @Binding var isAboutPresented: Bool

    var body: some View {
        Button(action: {
            isAboutPresented = true
        }) {
            Image("about")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .frame(width: 180, height: 40)
    }
}

struct AboutView: View {
    @Binding var isAboutPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack {
                Text("Image Assets Courtesy of Google Whisk")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()

                Text("Sound Assets Provided by Pixabay")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()

                Text("Background Music by PandaBeats")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()

                Text("All assets are free to use")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()

                Button("Close") {
                    isAboutPresented = false
                }
                .font(.headline)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
        }
    }
}


#Preview {
    ContentView()
}
