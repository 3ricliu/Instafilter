//
//  ContentView.swift
//  Instafilter
//
//  Created by Eric Liu on 11/13/20.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins


struct ContentView: View {
  @State private var image: Image?
  @State private var filterIntensity = 0.5
  @State private var filterRadius: Double = 100
  @State private var filterScale: Double = 10
  
  @State private var currentFilterName = "Sepia Tone"
  @State private var showingFilterSheet = false
  @State private var showingImagePicker = false
  @State private var inputImage: UIImage?
  @State private var processedImage: UIImage?
  
  @State private var showingSaveAlert = false

  @State var currentFilter: CIFilter = CIFilter.sepiaTone()
  let context = CIContext()

  var body: some View {
    let intensity = Binding<Double>(
      get: {
        self.filterIntensity
      },
      set: {
        self.filterIntensity = $0
        self.applyProcessing()
      }
    )
    let radius = Binding<Double>(
      get: {
        self.filterRadius
      },
      set: {
        self.filterRadius = $0
        self.applyProcessing()
      }
    )
    let scale = Binding<Double>(
      get: {
        self.filterScale
      },
      set: {
        self.filterScale = $0
        self.applyProcessing()
      }
    )
    return NavigationView {
      VStack {
        ZStack {
          Rectangle()
            .fill(Color.secondary)
          
          if let image = image {
            image
              .resizable()
              .scaledToFit()
          } else {
            Text("Tap to select a picture")
              .foregroundColor(.white)
              .font(.headline)
          }
        }
        .onTapGesture {
          self.showingImagePicker = true
        }
        Text(currentFilterName)
          .padding(.top)
        
        
        HStack {
          Text("Intensity")
          Slider(value: intensity)
        }.padding(.vertical)
        HStack {
          Text("Radius")
          Slider(value: radius)
        }.padding(.vertical)
        HStack {
          Text("Scale")
          Slider(value: scale)
        }.padding(.vertical)
        
        
        HStack {
          Button("Change Filter") {
            self.showingFilterSheet = true
          }
          
          Spacer()
          
          Button("Save") {
            guard let processedImage = self.processedImage else {
              self.showingSaveAlert.toggle()
              return
            }
            
            let imageSaver = ImageSaver()
            
            imageSaver.successHandler = {
              print("Success!")
            }
            
            imageSaver.errorHandler = {
              print("Oops: \($0.localizedDescription)")
            }
            
            imageSaver.writeToPhotoAlbum(image: processedImage)
          }
        }
      }
      .padding([.horizontal, .bottom])
      .navigationBarTitle("Instafilter")
      .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
        ImagePicker(image: self.$inputImage)
      }
      .actionSheet(isPresented: $showingFilterSheet) {
        ActionSheet(title: Text("Select a filter"), buttons: [
          .default(Text("Crystallize")) { self.setFilter(CIFilter.crystallize(), "Crystallize") },
          .default(Text("Edges")) { self.setFilter(CIFilter.edges(), "Edges") },
          .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur(), "Gaussian Blur") },
          .default(Text("Pixellate")) { self.setFilter(CIFilter.pixellate(), "Pixellate") },
          .default(Text("Sepia Tone")) { self.setFilter(CIFilter.sepiaTone(), "Sepia Tone") },
          .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask(), "Unsharp Mask") },
          .default(Text("Vignette")) { self.setFilter(CIFilter.vignette(), "Vignette") },
          .cancel()
        ])
      }
      .alert(isPresented: $showingSaveAlert) {
        Alert(title: Text("Whoops"), message: Text("Please select a picture first!"), dismissButton: .default(Text("👌🏼")))
      }
    }
  }
  
  func loadImage() {
    guard let inputImage = inputImage else { return }
    let beginImage = CIImage(image: inputImage)
    currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
    applyProcessing()
  }
  
  func applyProcessing() {
    let inputKeys = currentFilter.inputKeys
    if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
    
    if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
    
    if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey)}

    guard let outputImage = currentFilter.outputImage
    else { return }
    
    if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
      let uiImage = UIImage(cgImage: cgimg)
      processedImage = uiImage
      image = Image(uiImage: uiImage)
    }
  }
  
  func setFilter(_ filter: CIFilter, _ name: String) {
    self.currentFilter = filter
    self.currentFilterName = name
    loadImage()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
