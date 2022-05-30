/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct JobView: View {
  let job: JobModel
  @EnvironmentObject var jobConnectionManager: JobConnectionManager

  var body: some View {
    List {
      HStack {
        Label(
          title: {
            Text("Due Date")
              .font(.headline)
          },
          icon: {
            Image(systemName: "calendar")
          })
        Spacer()
        Text("\(job.dueDate, formatter: DateFormatter.dueDateFormatter)")
      }
      HStack {
        Label(
          title: {
            Text("Payout")
              .font(.headline)
          },
          icon: {
            Image(systemName: "creditcard")
          })
        Spacer()
        Text(job.payout)
      }
      Section(
        header: HStack(spacing: 8) {
          Text("Available Employees")
          Spacer()
          ProgressView()
        }) {
        ForEach(jobConnectionManager.employees, id: \.self) { employee in
          HStack {
            Text(employee.displayName)
              .font(.headline)
            Spacer()
            Image(systemName: "arrowshape.turn.up.right.fill")
          }
          .onTapGesture {
            jobConnectionManager.invitePeer(employee, to: job)
          }
        }
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationTitle(job.name)
    .onAppear {
      jobConnectionManager.startBrowsing()
    }
    .onDisappear {
      jobConnectionManager.stopBrowsing()
    }
  }
}

#if DEBUG
struct JobView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      JobView(job: JobModel(name: "Test Job", dueDate: Date(), payout: "$25.00"))
        .environmentObject(JobConnectionManager())
    }
  }
}
#endif
