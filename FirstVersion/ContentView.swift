import SwiftUI
class Subject: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    @Published var hours: Int
    @Published var minutes: Int
    @Published var dateAdded: Date
    
    init(name: String, hours: Int = 0, minutes: Int = 0, dateAdded: Date = Date()) {
        self.name = name
        self.hours = hours
        self.minutes = minutes
        self.dateAdded = dateAdded
    }
}
class Subjects: ObservableObject {
    @Published var list: [Subject] = []
}
struct ContentView: View {
    @State private var currentPage = 0
    @StateObject private var subjects = Subjects()
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomeView()
                .tag(0)
            TallyPageView(currentPage: $currentPage, subjects: subjects)
                .tag(1)
            TimeReportView(currentPage: $currentPage, subjects: subjects)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}
struct TallyPageView: View {
    @Binding var currentPage: Int
    @ObservedObject var subjects: Subjects
    @State private var showAddSubjectView = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(red: 219/255, green: 239/255, blue: 152/255)
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if subjects.list.isEmpty {
                            EmptyView()
                        } else {
                            ForEach(subjects.list) { subject in
                                SubjectView(subject: subject, subjects: subjects)
                            }
                        }
                    }
                    .padding()
                }
                VStack {
                    Spacer()
                    addButton
                }
            }
            BottomBarView(currentPage: $currentPage)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showAddSubjectView = true
        }) {
            Image(systemName: "plus")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color(red: 96/255, green: 92/255, blue: 184/255)))
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 4)
        }
        .padding(.bottom, 80)
        .sheet(isPresented: $showAddSubjectView) {
            AddSubjectView(subjects: subjects)
        }
    }
}
struct SubjectView: View {
    @ObservedObject var subject: Subject
    @ObservedObject var subjects: Subjects
    @State private var showTimePicker = false
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    
    var body: some View {
        HStack {
            Text(subject.name)
                .font(.title3)
                .padding()
            Spacer()
            Button(action: {
                showTimePicker = true
            }) {
                Image(systemName: "plus")
                    .padding()
                    .background(Color(red: 117/255, green: 235/255, blue: 200/255))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .sheet(isPresented: $showTimePicker) {
                TimePickerView(subject: subject, selectedHours: $selectedHours, selectedMinutes: $selectedMinutes, subjects: subjects)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 4)
    }
}
struct TimePickerView: View {
    @ObservedObject var subject: Subject
    @Binding var selectedHours: Int
    @Binding var selectedMinutes: Int
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var subjects: Subjects
    var body: some View {
        VStack {
            Text("Add Time Spent")
                .font(.headline)
                .padding()
            HStack {
                Picker("Hours", selection: $selectedHours) {
                    ForEach(0..<24) { hour in
                        Text("\(hour) hr").tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
                .clipped()
                
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(0..<60) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
                .clipped()
            }
            .padding()
            
            Button(action: {
                let totalMinutes = subject.minutes + selectedMinutes
                subject.hours += selectedHours + totalMinutes / 60
                subject.minutes = totalMinutes % 60
                subject.objectWillChange.send() // Force subject to update
                subjects.objectWillChange.send() // Explicitly notify that Subjects has changed
                print("Updated: \(subject.name) - \(subject.hours) hr \(subject.minutes) min")
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Add Time")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}
struct AddSubjectView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var subjects: Subjects
    @State private var subjectName: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add a New Subject")
                .font(.headline)
                .padding()
            TextField("Enter subject name", text: $subjectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button(action: {
                if !subjectName.isEmpty {
                    let newSubject = Subject(name: subjectName)
                    subjects.list.append(newSubject)
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Add Subject")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 96/255, green: 92/255, blue: 184/255))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
struct TimeReportView: View {
    @Binding var currentPage: Int
    @ObservedObject var subjects: Subjects
    @State private var showMonthlyReport = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(red: 219/255, green: 239/255, blue: 152/255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Title
                    Text("Time Report")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                    
                    // Scrollable list of subjects
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(subjects.list) { subject in
                                HStack {
                                    Text(subject.name)
                                        .font(.title3)
                                        .padding()
                                    Spacer()
                                    Text("\(subject.hours) hr \(subject.minutes) min")
                                        .padding()
                                        .background(Color(red: 117/255, green: 235/255, blue: 200/255))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 4)
                            }
                        }
                        .padding()
                    }
                    
                    // Monthly Report Button
                    monthlyReportButton
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Bottom Bar
                    BottomBarView(currentPage: $currentPage)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .edgesIgnoringSafeArea(.bottom)
                }
            }
        }
        .sheet(isPresented: $showMonthlyReport) {
            // Present your monthly report view here
            MonthlyReportView(subjects: subjects)
        }
    }
    
    private var monthlyReportButton: some View {
        Button(action: {
            showMonthlyReport = true
        }) {
            Text("My Monthly Report")
                .foregroundColor(.white)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 96/255, green: 92/255, blue: 184/255))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 4)
        }
    }
}

struct MonthlyReportView: View {
    @ObservedObject var subjects: Subjects
    
    var body: some View {
        // Get the current month
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        
        // Calculate total hours and minutes for the current month
        let totalMinutes = subjects.list.reduce(0) { total, subject in
            total + subject.hours * 60 + subject.minutes
        }
        
        let totalHours = totalMinutes / 60
        let remainingMinutes = totalMinutes % 60
        
        VStack(spacing: 20) {
            // Title
            Text("Monthly Report")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 96/255, green: 92/255, blue: 184/255))
                .padding()
            
            // Total Time Spent Title
            Text("Total Time Spent in \(calendar.monthSymbols[currentMonth - 1])")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 145/255, green: 119/255, blue: 184/255))
                .padding()
            
            // Display total hours and minutes
            Text("\(totalHours) hr \(remainingMinutes) min")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 96/255, green: 194/255, blue: 164/255))
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
}


struct BottomBarView: View {
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 50) {
            Button(action: {
                currentPage = 1
            }) {
                Image(systemName: "clock")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(red: 136/255, green: 224/255, blue: 208/255))
                    .font(.system(size: 30, weight: currentPage == 1 ? .bold : .regular))
            }
            Button(action: {
                currentPage = 2
            }) {
                Image(systemName: "chart.bar")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(red: 136/255, green: 224/255, blue: 208/255))
                    .font(.system(size: 30, weight: currentPage == 2 ? .bold : .regular))
            }
        }
    }
}
struct WelcomeView: View {
    var body: some View {
        ZStack {
            Color(red: 219/255, green: 239/255, blue: 152/255)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Text("TimeTally")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 2, y: 2)
                    .padding(.top, -100)
                Spacer()
                Text("<<<")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 2, y: 2)
                    .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
