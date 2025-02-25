//
//  TutorialView.swift
//  SSC_BoxingMayhem
//
//  Created by Kurnia Kharisma Agung Samiadjie on 24/02/25.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameService: GameService
    @State private var currentStep = 0
    @State private var showingHint = false
    @State private var hintText = ""
    @State private var gameStarted = false
    @State private var showingLightingCheck = true
    
    let tutorialSteps = [
        (move: "jab", description: "Let's start with a JAB\nPunch straight forward for a quick jab!\n\nNote: Each punch uses stamina. Watch your stamina bar!"),
        (move: "hook", description: "Great! Now try a HOOK\nSwing your arm horizontally for a hook!\n\nTip: Your stamina recovers over time."),
        (move: "uppercut", description: "Finally, the UPPERCUT\nPunch upward for an uppercut!\n\nRemember: Low stamina makes your punches weaker!"),
        (move: "combo", description: "One last tip!\nDon't throw more than 3 consecutive punches of the same type.\nMix up your moves for better results!\n\nExample: After jab-jab-jab, switch to a different punch!")
    ]
    
    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .background(Color.blue.secondary)
                .ignoresSafeArea(.all)
            
            if gameService.playerStamina < 25 {
                Color.yellow
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: gameService.playerStamina < 25)
            }
            
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            if showingLightingCheck {
                VStack(spacing: 20) {
                    Text("Before we start...")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Spacer()
                    
                    HStack {
                        Text("Make sure you're in a well-lit room\nand your camera can see you clearly!")
                            .font(.title2)
                            .fixedSize()
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(15)

                        Image("tutorial-1")
                            .resizable()
                            .frame(width: 240, height: 135)
                    }
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingLightingCheck = false
                            gameStarted = true
                        }
                    }) {
                        Text("I'm Ready!")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 200)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            } else {
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            StaminaBar(charInfo: CharInfo.player)
                            HStack {
                                Text("State: " + gameService.playerState)
                                    .padding(16)
                                    .foregroundStyle(.white)
                                    .fontWeight(.bold)
                                    .background(.blue)
                                    .cornerRadius(20)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.leading, 16)
             
                    if currentStep < tutorialSteps.count {
                        Text(tutorialSteps[currentStep].description)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(15)
                            .padding()
                            .fixedSize()
                    } else {
                        Text("Great job! You've learned all the basic moves!\nTry them out in a real match!")
                            .font(.title2)
                            .fixedSize()
                            .bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(15)
                            .padding()
                    }
                    Spacer()
                }
                
                Character(info: CharInfo.player,
                          state: $gameService.playerState,
                          isFlipped: $gameService.playerFlipped)
                    .position(x: Device.width/2, y: Device.height - 100)
                
                // Hint Popup
                if showingHint {
                    Text(hintText)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .position(x: Device.width/2, y: Device.height/2)
                }
                
                if gameStarted {
                    VideoPreview()
                        .ignoresSafeArea(.all)
                        .environmentObject(gameService)
                        .onChange(of: gameService.playerState) { newState in
                            handleStateChange(newState)
                        }
                        
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                        gameService.resetGame()
                        AudioManager.shared.stopSound("crowd")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            setupTutorial()
        }
    }
    
    private func setupTutorial() {
        gameService.gameState = "fight"
        gameService.isShowingTutorial = true
        AudioManager.shared.playSound("crowd")
        AudioManager.shared.setVolume(0.1, for: "crowd")
    }
    
    private func handleStateChange(_ newState: String) {
        guard currentStep < tutorialSteps.count else { return }
        
        let expectedMove = tutorialSteps[currentStep].move
        
        if newState == expectedMove {
            showSuccess()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                currentStep += 1
            }
        }
    }
    
    private func showSuccess() {
        hintText = "Great move! 👊"
        withAnimation {
            showingHint = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                showingHint = false
            }
        }
    }
}

#Preview {
    TutorialView()
        .environmentObject(GameService())
}
