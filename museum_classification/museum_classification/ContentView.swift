import SwiftUI
import AVFoundation

struct ContentView: View {
    @ObservedObject private var viewModel = CameraViewModel()
    @State private var selectedArtifact: Artifact?

    var body: some View {
        ZStack {
            Color(hex: "#20484b")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Museum Logo
                if let logoImage = UIImage(named: "museum_logo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding()
                }
                
                // Camera Preview
                if viewModel.isShowingCamera {
                    CameraPreview(previewLayer: viewModel.getPreviewLayer())
                        .frame(height: 400)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .padding()
                }
                
                // Captured Image
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(10)
                        .padding()
                        .shadow(radius: 5)
                } else {
                    Text("尚未擷取圖像")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // Detected Artifacts Buttons
                if !viewModel.detectedArtifacts.isEmpty {
                    ScrollView {
                        VStack {
                            ForEach(viewModel.detectedArtifacts, id: \.self) { artifactName in
                                VStack {
                                    Button(action: {
                                        selectedArtifact = Artifact(name: artifactName)
                                    }) {
                                        Text(artifactName)
                                            .font(.headline)
                                            .padding()
                                            .foregroundColor(Color(hex: "#20484b"))
                                            .background(Color(hex: "#91bec5"))
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                    }
                                    
                                    // Show failure message if the artifact is "未知類別"
                                    if artifactName == "未知類別" {
                                        Text("""
                                        辨識失敗:
                                        1.您辨識的東西不在辨識範圍
                                        2.您可能需要調整位置重拍
                                        """)
                                        .font(.body)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 5)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 250) // Adjust the height as needed
                    .padding()
                }


                
                // Action Buttons
                HStack {
                    CustomButton(title: "打開相機") {
                        viewModel.openCamera()
                    }
                    
                    CustomButton(title: "處理相片") {
                        viewModel.getFinalResult()
                    }
                }
                .padding()
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    
                    if errorMessage.contains("相機權限被拒絕") {
                        Button("打開設置") {
                            viewModel.openSettings()
                        }
                        .font(.headline)
                        .foregroundColor(Color(hex: "#91bec5"))
                    }
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.setupCamera()
            viewModel.loadModels()
        }
        .sheet(isPresented: $viewModel.isShowingCamera) {
            ImagePicker(image: $viewModel.capturedImage, sourceType: .camera)
        }
        .sheet(item: $selectedArtifact) { artifact in
            ArtifactDetailView(artifact: artifact.name)
        }
    }
}

// Custom Button
struct CustomButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding()
                .foregroundColor(Color(hex: "#20484b"))
                .background(Color(hex: "#91bec5"))
                .cornerRadius(10)
                .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
}

// CameraPreview for AVCaptureVideoPreviewLayer
struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

// Color Extension for HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = scanner.string.index(after: scanner.string.startIndex)
        }
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// Artifact Detail View
struct ArtifactDetailView: View {
    var artifact: String
        
        var body: some View {
            VStack {
                                
                // Artifact details card
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Optional Image placeholder
                        if let image = UIImage(named: getArtifactImageName(artifact)) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        // Artifact Title
                        Text(artifact)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#20484b"))
                            .padding(.horizontal)
                        
                        // Artifact Description
                        Text(getArtifactDetails(artifact))
                            .font(.body)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding()
                
                Spacer()
            }
            .background(Color(.systemGray6).opacity(0.9))
        }
        
    
    func getArtifactDetails(_ artifact: String) -> String {
        switch artifact {
        case "蟠龍方壺":
            return """
            銅器

            春秋中期

            高88.8 寬45.6 厚35.8

            代管

            登錄號：h0000286

            國立歷史博物館藏《蟠龍方壺》（館藏編號h0000286），此件出土時為一對，另一件現藏於北京故宮博物院，同墓另有一對蓮鶴方壺出土。此器蓋沿寬厚，上接鏤空網狀的蟠蛇紋蓋冠，雙耳作回首龍形的立體鏤空圓雕，垂腹有十字形凸稜，圈足下設有承壺伏虎一對，虎呈吐舌捲尾姿態，器面飾有繁複的帶狀蟠龍紋，此件係於1923年出土於河南新鄭鄭公大墓，為河南博物館舊藏文物，1956年經教育部撥交予本館典藏，並於2011年經文化部公告為國寶。
            鄭公大墓係於1923年8月在河南新鄭李家樓發掘出土，為春秋中晚期鄭國貴族墓葬，其出土文物數量可觀、製作精美，其風格除可見繼承西周文化傳統，也呈現晉、楚文化特色的融合。此件壺身與1979年河南淅川下寺遺址出土的《 龍耳虎足方壺》器形、裝飾均相似，可作為春秋時期楚式龍耳方壺的代表。
            """
        case "虎形尊":
            return """
            銅器

            春秋中期

            長35.8 高21.9

            登錄號：h0000282

            國立歷史博物館藏《虎形尊》（館藏編號h0000282），尊為酒器，全器作虎形，以虎口作為流口，背具圓形蓋並串鏈與尾相連接，虎尾向上彎捲形成把手，短頸肥身，四足甚短，虎目圓睜，短豎耳，頭頂有扉稜，額部及足部飾有重環紋，尾部則以鱗紋為飾。此件係於1923年出土於河南新鄭鄭公大墓，為河南博物館舊藏文物，1956年經教育部撥交予本館典藏，並於2011年經文化部公告為重要古物。
            鄭公大墓係於1923年8月在河南新鄭李家樓發掘出土，為春秋中晚期鄭國貴族墓葬，其出土文物數量可觀、製作精美，其風格除可見繼承西周文化傳統，也呈現晉、楚文化特色的融合。
            """
        case "獸形器座":
            return """
            銅器

            春秋中期

            高47 長34 寬30

            登錄號：h0000289

            國立歷史博物館藏《獸形器座》（館藏編號h0000289），這件為獸面人身的座狀物，有著獸面、大眼、張口、人身的特徵，袒胸露腹，雙足緊踏著捲曲的蟠蛇，蛇身滿布尖刺，其頭部有4條向上的曲柱殘痕，上承物已失，或作為承盤一類的器物底座，此器造型威猛而獨特，此件係於1923年出土於河南新鄭鄭公大墓，為河南博物館舊藏文物，1956年經教育部撥交予本館典藏，並於2011年經文化部公告為國寶。
            鄭公大墓係於1923年8月在河南新鄭李家樓發掘出土，為春秋中晚期鄭國貴族墓葬，其出土文物數量可觀、製作精美，其風格除可見繼承西周文化傳統，也呈現晉、楚文化特色的融合。
            """
        case "青花花鳥八角盒":
            return """
            瓷器

            明

            高18.4 寬32

            登錄號：80-00031

            國立歷史博物館藏《青花花鳥八角盒》（館藏編號80-00031），平頂，蓋面微鼓，器、盒以子母口套合，盒下置八角圈足。蓋面、蓋身、盒身各面以青花繪飾鳥雀戲於花果枝葉間，桃實、靈芝圖案寓意長壽，各面邊緣及圈足中央均飾青線共有七道，構圖繁複，青花發色明豔，器底釉下青花書「大明嘉靖年製」雙行六字楷款，內壁素白無紋。
            「青花」瓷器是在瓷胎上用鈷料描繪紋飾，再施一層透明釉後以高溫燒造而成。最晚在十四世紀的元代中國，江西景德鎮已成功燒製出青花瓷器，而後盛行於明清。瓷盒是明代嘉靖、萬曆朝常見器形之一，有方形、八角形、銀錠形、鏤空器等，樣式繁多。由於嘉靖皇帝道教信仰關係，瓷器上也常見永壽求仙有關題材的紋飾。本件有款八角蓋盒具有重要時代特色，器形大，造型特殊，工藝技術表現佳，本館於1991年購藏，2010年經文化部指定為重要古物。

            """
        case "三彩馬":
            return """
            陶器

            唐

            高74.8 長73.5 寬38.4

            23360g

            代管

            登錄號：h0000030

            國立歷史博物館藏《三彩馬》（館藏編號h0000030），此件唐代三彩馬直立於平板上，頭略向左偏，低首靜立，姿態優雅。頭前馬鬃分纓，頸背鬃毛梳剪整齊，馬首配戴絡頭，額飾當盧，攀胸及鞧帶均有鈴鐺及杏葉飾物，馬背配鞍，其上舖有毛毯，縛尾上翹，裝飾極為華麗，馬身整體施以黃褐釉，馬具、垂飾、鞍褥等以綠釉為主，馬鬃殘留白釉，馬尾則無釉，釉色鮮麗，整體比例正確，體型健碩勻稱、四肢細挺有力，適切表現其雄偉英姿。此件為1956年經教育部撥交予本館典藏，原為中國河南博物院典藏文物，2010年經文化部公告為重要古物。
            唐代盛行的三彩陶器是一種多彩陶器，常簡稱為唐三彩，主要用於隨葬。三彩陶器是以陶土作胎，先入窯素燒（約1100度），取出上釉，釉料包含各種著色劑和助熔劑，上釉完成後再進行第二次低溫燒製（約800度）。製作時常利用釉料流動特性，使不同色釉相互交融，呈現斑斕美感。
            """
        case "金柄銅短劍":
            return """
            金柄銅短劍
            銅器

            春秋

            長30.8cm 寬3.9cm 厚0.32cm

            320g

            代管

            登錄號：h0000382

            國立歷史博物館藏《金柄銅短劍》（館藏編號h0000382），此器劍身較長，中脊凸起，兩鍔窄薄，劍柄部分為金質，裝飾精美，劍格處以饕餮紋為主，兩側有穿孔，莖作螺旋狀紋，劍首中空，呈橢圓形，並以繁複的蟠螭紋為飾。此件係於1936年出土於春秋中晚期河南省輝縣琉璃閣的甲墓，為河南博物館舊藏文物，1956年經教育部撥交予本館典藏，並於2011年經文化部公告為重要古物。
            1936年河南博物館進行了輝縣琉璃閣的甲、乙兩座大墓發掘，墓坑出土銅器、玉器、陶器等千餘件文物，目前學界多推測墓主為春秋中晚期卿一級人物。            
            """
        case "三彩加藍人面鎮墓獸":
            return """
            陶器

            唐

            高127 寬57.2

            登錄號：90-00647

            國立歷史博物館藏《三彩加藍人面鎮墓獸》（館藏編號90-00647），人面獸身，蹲踞於臺座上。頭部未施釉，有繪彩痕跡，凸眼豎眉，利牙卷鬚，扇形大耳，額上三隻叉角，鬃髮豎起狀如火焰，面容猙獰，震懾人心。頭後方有一高聳的戈戟狀物，胸前飾以卷草圖案及斜刻紋，兩側另有火焰形翅，獸形足，卷狀尾，背後塑有齒狀脊飾，全身施以黃、褐、綠彩，胸前尚有罕見的藍彩，釉色鮮麗，裝飾性強烈。
            三彩陶意指多彩陶，盛行於唐代，故稱唐三彩，主要用於隨葬。三彩陶以陶土作胎，先入窯素燒（約1100度），取出上釉，釉料包含各種著色劑和助熔劑，上釉完成後再進行第二次低溫燒製（約800度）。鎮墓獸造型凶猛，結合了猛獸、胡人及漢人的外形和神態，作為墓地的守護神，用以避邪並護佑墓室的安寧。
            本件鎮墓獸品相完整，形體雄偉，裝飾紋樣精美，並有少見的藍彩釉色，本館於2001年購藏，2010年經文化部指定為重要古物。

            """
        default:
            return "辨識失敗:\n1.您辨識的東西不在辨識範圍\n2.您可能需要調整位置重拍"
        }
    }
    // Function to get image name based on artifact
    func getArtifactImageName(_ artifact: String) -> String {
        switch artifact {
        case "蟠龍方壺":
            return "panlong_fanghu" // Use the name of your image asset
        case "虎形尊":
            return "huxing_zun"
        case "獸形器座":
            return "shouxing_qizuo"
        case "青花花鳥八角盒":
            return "qinghua_huaniao_bajiaohe"
        case "三彩馬":
            return "sancai_ma"
        case "金柄銅短劍":
            return "jinbing_tongduanjian"
        case "三彩加藍人面鎮墓獸":
            return "sancai_jialan_renmianzhenmushou"
        default:
            return "default_image" // Fallback image
        }
    }
    func dismiss() {
            // Code to dismiss the view
    }
}

// Artifact model for selection
struct Artifact: Identifiable {
    let id = UUID()
    let name: String
}
