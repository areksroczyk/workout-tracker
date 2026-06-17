import SwiftUI

struct SetRowView: View {
    @Bindable var set: SetDraft
    let onCompleted: () -> Void
    let onChanged: () -> Void

    @State private var weightText = ""
    @State private var repsText = ""

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 36)

            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .onChange(of: weightText) {
                    if let value = Decimal(string: weightText) {
                        set.weightKg = value
                        onChanged()
                    }
                }

            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .onChange(of: repsText) {
                    if let value = Int(repsText) {
                        set.reps = value
                        onChanged()
                    }
                }

            Button {
                set.completed.toggle()
                onChanged()
                if set.completed {
                    onCompleted()
                }
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.completed ? .green : .gray)
            }
            .frame(width: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(set.completed ? .green.opacity(0.05) : .clear)
        .onAppear {
            if set.weightKg > 0 { weightText = "\(set.weightKg)" }
            if set.reps > 0 { repsText = "\(set.reps)" }
        }
    }
}
