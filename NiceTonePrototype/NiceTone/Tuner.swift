import AudioKit
import AudioKitEX
import AudioKitUI
import AudioToolbox
import SoundpipeAudioKit
import SwiftUI

struct TunerData {
    var pitch: Float = 0.0
    var amplitude: Float = 0.0
    var noteNameWithSharps = "-"
    var noteNameWithFlats = "-"
    var musicNote = "..."
    var baseNote = "..."
}

class TunerConductor: ObservableObject, HasAudioEngine {
    @Published var data = TunerData()
    @Published var base = FrequencyView()

    let engine = AudioEngine()
    let initialDevice: Device

    let mic: AudioEngine.InputNode
    let tappableNodeA: Fader
    let tappableNodeB: Fader
    let tappableNodeC: Fader
    let silence: Fader

    var tracker: PitchTap!
    
    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    init() {
        guard let input = engine.input else { fatalError() }

        guard let device = engine.inputDevice else { fatalError() }

        initialDevice = device

        mic = input
        tappableNodeA = Fader(mic)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        silence = Fader(tappableNodeC, gain: 0)
        engine.output = silence

        tracker = PitchTap(mic) { pitch, amp in
            DispatchQueue.main.async {
                self.update(pitch[0], amp[0])
            }
        }
        tracker.start()
    }
    
    

    func update(_ pitch: AUValue, _ amp: AUValue) {
        // Reduces sensitivity to background noise to prevent random / fluctuating data.
        guard amp > 0.1 else { return }

        data.pitch = pitch
        data.amplitude = amp

        var frequency = pitch
        while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
            frequency /= 2.0
        }
        while frequency < Float(noteFrequencies[0]) {
            frequency *= 2.0
        }

        
        var minDistance: Float = 10000.0
        var index = 0

        for possibleIndex in 0 ..< noteFrequencies.count {
            let distance = fabsf(Float(noteFrequencies[possibleIndex]) - frequency)
            if distance < minDistance {
                index = possibleIndex
                minDistance = distance
            }
        }
        let octave = Int(log2f(pitch / frequency))
        data.noteNameWithSharps = "\(noteNamesWithSharps[index])\(octave)"
        data.noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
        data.baseNote = getBaseNoteName(Double(pitch))
        let musicNote = frequencyToNote(Double(pitch), base.frequency )
        if (data.musicNote != ".") {
            if (!musicNote.elementsEqual(".")) {
                data.musicNote = musicNote
            }
        }
        
    }
    
    // function to convert the frequency to music node in concert pitch
    func frequencyToNote(_ frequency: Double, _ baseFrequency: Double) -> String {
//        let a = 440.0 // frequency of A4 note in Hz
        let twelfthRootOfTwo = pow(2.0, 1.0/12.0)
        let halfStepsFromA4 = log(frequency/baseFrequency) / log(twelfthRootOfTwo)
        let noteNames = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]
        let noteIndex = Int(round(halfStepsFromA4)) % 12
        let octave = Int(floor((halfStepsFromA4 + 9.0) / 12.0))
        print("Frequency \(frequency) > ")
        print("twelfthRootOfTwo \(twelfthRootOfTwo) ")
        print("halfStepsFromA4 \(halfStepsFromA4) ")
        print("noteIndex \(noteIndex) ")
        print("octave \(octave) \n")
        
        if(noteIndex >= 0) {
            return "\(noteNames[noteIndex])\(octave)"
        } else {
            return "."
        }
    }
    
    // function to get base note name based on frequency selection
    func getBaseNoteName(_ frequency: Double) -> String {
        let notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let noteNumber = 12 * log2(frequency / 440.0) + 69
        let index = Int(noteNumber.rounded()) % notes.count
        return notes[index]
    }
}

struct TunerView: View {
    @StateObject var conductor = TunerConductor()
    @Binding var frequency: Double

    var body: some View {
        VStack {
            HStack {
                Text("Frequency")
                Spacer()
                Text("\(conductor.data.pitch, specifier: "%0.1f")")
            }.padding()

            HStack {
                Text("Amplitude")
                Spacer()
                Text("\(conductor.data.amplitude, specifier: "%0.1f")")
            }.padding()

            HStack {
                Text("Note Name")
                Spacer()
                Text("\(conductor.data.noteNameWithSharps) / \(conductor.data.noteNameWithFlats)")
            }.padding()
            
            HStack {
                Text("Music Note")
                Spacer()
                Text("\(conductor.data.musicNote) > \(frequency, specifier: "%0.1f") ")
            }.padding()
            
            HStack {
                Text("Base Music Note")
                Spacer()
                Text("\(conductor.data.baseNote) > \(frequency, specifier: "%0.1f") ")
            }.padding()


            InputDevicePicker(device: conductor.initialDevice)

            NodeRollingView(conductor.tappableNodeA).clipped()

            NodeOutputView(conductor.tappableNodeB).clipped()

            NodeFFTView(conductor.tappableNodeC).clipped()
        }
      
        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
    }
}

struct InputDevicePicker: View {
    @State var device: Device

    var body: some View {
        Picker("Input: \(device.deviceID)", selection: $device) {
            ForEach(getDevices(), id: \.self) {
                Text($0.deviceID)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onChange(of: device, perform: setInputDevice)
    }

    func getDevices() -> [Device] {
        AudioEngine.inputDevices.compactMap { $0 }
    }

    func setInputDevice(to device: Device) {
        do {
            try AudioEngine.setInputDevice(device)
        } catch let err {
            print(err)
        }
    }
}
