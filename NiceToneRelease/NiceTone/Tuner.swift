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

struct CustomCenter: AlignmentID {
  static func defaultValue(in context: ViewDimensions) -> CGFloat {
    context[HorizontalAlignment.center]
  }
}

extension HorizontalAlignment {
  static let customCenter: HorizontalAlignment = .init(CustomCenter.self)
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

let notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
let freq = [261.0, 277.0, 293.0, 311.0, 329.0, 349.0, 370.0, 392.0, 415.0, 440.0, 466.0, 493.0]

func setCurrentFrequency(note: String) -> Double {
    
    var frequency: Double
    
    switch note {
    case notes[0]:
        frequency = freq[0]
    case notes[1]:
        frequency = freq[1]
    case notes[2]:
        frequency = freq[2]
    case notes[3]:
        frequency = freq[3]
    case notes[4]:
        frequency = freq[4]
    case notes[5]:
        frequency = freq[5]
    case notes[6]:
        frequency = freq[6]
    case notes[7]:
        frequency = freq[7]
    case notes[8]:
        frequency = freq[8]
    case notes[9]:
        frequency = freq[9]
    case notes[10]:
        frequency = freq[10]
    case notes[11]:
        frequency = freq[11]
    default:
        frequency = freq[9]
    }
    
    return frequency
}

struct TunerView: View {
    @StateObject var conductor = TunerConductor()
    @Binding var frequency: Double
    @State private var selection = "A"

    var body: some View {
        VStack(alignment: .customCenter) {
            HStack {
                VStack {
                    Text("Amplitude")
                    Spacer()
                    Text("\(conductor.data.amplitude, specifier: "%0.1f")")
                }.padding()
                
                VStack {
                    Text("Note Name")
                    Spacer()
                    Text("\(conductor.data.noteNameWithSharps) / \(conductor.data.noteNameWithFlats)")
                }.padding()
            }
            HStack {
                VStack {
                    Text("Music Note")
                    Spacer()
                    Text("\(conductor.data.musicNote) > \(frequency, specifier: "%0.1f") ")
                }.padding()
                
                VStack {
                    Text("Base Music Note")
                    Spacer()
                    Text("\(conductor.data.baseNote) > \(frequency, specifier: "%0.1f") ")
                }.padding()
            }
            HStack {
                VStack {
                    Text("Target Note")
                    Spacer()
                    Picker("Select Note", selection: $selection) {
                        ForEach(notes, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .onChange(of: selection) { newValue in
                        frequency = setCurrentFrequency(note: newValue)
                    }
                }
            }
            
            //value = current notefrequency, in: lower note frequency ... higher note frequency
            Gauge(value: conductor.data.pitch, in: Float(Int(frequency/2))...Float(Int(frequency))*2) {
            } currentValueLabel: {
                //display current note here
                Text("Current note")
            }  minimumValueLabel: {
                //insert note in lower boundary
                Text("\(Float(Int(frequency/2)), specifier: "%0.1f")")
                    .foregroundColor(.black)
            } maximumValueLabel: {
                //insert note in higher boundary
                Text("\(Float(Int(frequency)*2), specifier: "%0.1f")")
                    .foregroundColor(.black)
            }.gaugeStyle(GaugeStyleView(targetFrequency: $frequency, targetNote: $selection))
            
            HStack
            {
                Text("\(conductor.data.pitch, specifier: "%0.1f")")
                    .font(.system(size: 30))
                    .alignmentGuide(.customCenter) {
                        $0[HorizontalAlignment.center]
                    }
                Text("Hz")
                    .font(.title3)
            }

            //InputDevicePicker(device: conductor.initialDevice)

            //NodeRollingView(conductor.tappableNodeA).clipped()

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
