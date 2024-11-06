<template>
  <div
    class="relative flex min-h-screen flex-col justify-center overflow-hidden py-6 sm:py-12 px-8 bg-gradient-to-r from-[#0d0d0d] to-[#1a1a1a] select-none"
  >
    <!-- Loading Square -->
    <div v-if="loading" class="loading-square">
      <div class="loading-animation">
        <div class="line line1"></div>
        <div class="line line2"></div>
        <div class="line line3"></div>
        <div class="line line4"></div>
      </div>
    </div>

    <!-- PIN Code Screen -->
    <div
      v-if="currentView === 'pin'"
      class="w-[400px] mx-auto p-8 bg-gray-900/60 rounded-xl shadow-lg text-center text-gray-100"
    >
      <h2 class="text-2xl font-bold text-[#00F9B9] mb-6">Enter PIN</h2>

      <!-- Pin Indicator Circles with Debugging -->
      <div class="flex justify-center space-x-2 mb-6">
        <span
          v-for="n in 4"
          :key="n"
          class="w-6 h-6 rounded-full transition-colors duration-200"
          :class="{
            'bg-[#00F9B9]': n <= pinInput.length,
            'bg-gray-700': n > pinInput.length,
          }"
        ></span>
      </div>

      <!-- Keypad Grid -->
      <div class="grid grid-cols-3 gap-4">
        <button
          v-for="n in 9"
          :key="n"
          class="bg-[#00F9B9] text-black rounded-md p-4 font-bold text-lg"
          @click="enterPin(n)"
        >
          {{ n }}
        </button>
        
        <button
          class="bg-gray-500 text-gray-300 rounded-md p-4 font-bold text-lg"
          @click="clearPin"
        >
          Clear
        </button>
        <button
          class="bg-[#00F9B9] text-black rounded-md p-4 font-bold text-lg"
          @click="enterPin(0)"
        >
          0
        </button>
        <button
          class="bg-[#00F9B9] text-black rounded-md p-4 font-bold text-lg"
          @click="submitPin"
        >
          Enter
        </button>
      </div>

      <!-- Error Message -->
      <p v-if="message" class="text-red-500 mt-4">{{ message }}</p>
    </div>

    <!-- Main Content -->
    <div
      v-else
      class="relative w-[400px] border border-[#00F9B9] bg-black/20 backdrop-blur-2xl px-8 py-10 shadow-2xl ring-1 ring-gray-900/5 sm:mx-auto sm:rounded-3xl sm:px-12"
    >
      <div class="mx-auto max-w-md">
        <h1
          v-if="currentView === 'main'"
          class="text-3xl font-extrabold text-center text-[#00F9B9] mb-8"
        >
          Quantum ATM
        </h1>

        <div class="space-y-6 text-sm text-gray-300 select-none">
          <!-- Balance Display -->
          <div
            v-if="currentView === 'main'"
            class="flex flex-col items-center space-y-4"
          >
            <div
              class="bg-gradient-to-r from-[#00F9B9]/20 to-[#00F9B9]/30 p-5 rounded-xl shadow-md w-full text-center"
            >
              <p class="text-gray-100 text-3xl font-bold">${{ balance }}</p>
            </div>

            <!-- Card Display -->
            <div
              class="bg-gradient-to-r from-[#00F9B9]/20 to-[#00F9B9]/30 p-5 rounded-xl shadow-md w-full select-none"
            >
              <div class="flex justify-between items-center mb-4">
                <img
                  src="https://upload.wikimedia.org/wikipedia/commons/0/04/Visa.svg"
                  alt="Visa Logo"
                  class="h-8"
                />
                <p class="text-gray-100">Debit Card</p>
              </div>
              <p class="text-gray-100 text-xl tracking-wide mb-4">
                {{ ccData.longNum }}
              </p>
              <div class="flex justify-between items-center select-none">
                <div>
                  <p class="text-gray-400 text-xs">Card Holder</p>
                  <p class="text-gray-100">{{ ccData.name }}</p>
                </div>
                <div>
                  <p class="text-gray-400 text-xs">Expiry</p>
                  <p class="text-gray-100">{{ ccData.expiry }}</p>
                </div>
                <div>
                  <p class="text-gray-400 text-xs">CVV</p>
                  <p class="text-gray-100">{{ ccData.cvv }}</p>
                </div>
              </div>
            </div>

            <!-- Amount Input -->
            <input
              v-model="amount"
              type="number"
              placeholder="Enter amount"
              class="w-full px-4 py-3 border border-gray-600 rounded-lg bg-gray-900 text-gray-100 focus:outline-none focus:ring-2 focus:ring-[#00F9B9]"
            />

            <!-- Action Buttons -->
            <div class="flex space-x-4">
              <button
                @click="deposit"
                class="px-6 py-3 bg-[#00F9B9] text-black rounded-lg hover:bg-[#00d9a9] transform hover:scale-105 transition ease-in-out font-extrabold"
              >
                Deposit
              </button>
              <button
                @click="withdraw"
                class="px-6 py-3 bg-[#00F9B9] text-black rounded-lg hover:bg-[#00d9a9] transform hover:scale-105 transition ease-in-out font-extrabold"
              >
                Withdraw
              </button>
              <button
                @click="showHistory"
                class="px-6 py-3 bg-[#00F9B9] text-black rounded-lg hover:bg-[#00d9a9] transform hover:scale-105 transition ease-in-out font-extrabold"
              >
                History
              </button>
            </div>
            <p v-if="message" class="text-red-500 mt-4">{{ message }}</p>
          </div>
          <!-- Transaction History -->
          <div
            v-else-if="currentView === 'history'"
            class="flex flex-col items-center space-y-4 w-full"
          >
            <h2 class="text-xl font-bold text-[#00F9B9] mb-4">
              Transaction History
            </h2>
            <div class="w-full max-h-72 overflow-y-auto space-y-2">
              <div
                v-for="(transaction, index) in history"
                :key="index"
                class="bg-gray-800/30 p-4 rounded-lg shadow-md flex justify-between items-center"
              >
                <div class="text-gray-100">
                  <p class="text-sm">{{ transaction.date }}</p>
                  <p class="text-xs text-gray-400">{{ transaction.type }}</p>
                </div>
                <p
                  :class="{
                    'text-green-400':
                      transaction.type.toLowerCase() === 'deposit',
                    'text-red-400':
                      transaction.type.toLowerCase() === 'withdraw',
                  }"
                  class="font-semibold"
                >
                  {{
                    transaction.type.toLowerCase() === "deposit" ? "+" : "-"
                  }}${{ Math.abs(transaction.amount) }}
                </p>
              </div>
            </div>
            <button
              @click="goBack"
              class="mt-6 px-6 py-3 bg-[#00F9B9] text-black rounded-lg hover:bg-[#00d9a9] transform hover:scale-105 transition ease-in-out"
            >
              Back
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      balance: 0,
      amount: "",
      message: "",
      currentView: "pin",
      loading: false,
      history: [],
      ccData: {
        longNum: "1234 5678 9012 3456",
        name: "John Doe",
        expiry: "12/34",
        cvv: "123",
        correctPin: "1111",
      },
      pinInput: "",
    };
  },
  methods: {
    enterPin(number) {
      if (this.pinInput.length < 4) {
        this.pinInput += number.toString();
        console.log("Current PIN input:", this.pinInput); // Debugging
      }
    },
    clearPin() {
      this.pinInput = "";
      this.message = "";
      console.log("PIN input cleared"); // Debugging
    },
    submitPin() {
      if (this.pinInput === this.ccData.correctPin) {
        this.currentView = "main";
        this.pinInput = ""; // Reset PIN input after successful entry
        this.fetchBalance();
        this.fetchCCData();
      } else {
        this.message = "Incorrect PIN. Please try again.";
        this.clearPin();
        this.loading = false;
      }
    },
    fetchCCData() {
      fetch("https://your_resource_name/getCCData", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.success) {
            this.ccData = data.ccData;
          } else {
            console.warn(data.message);
          }
        })
        .catch((error) => {
          console.error("Error fetching card data:", error);
        });
    },
    fetchBalance() {
      this.loading = true;
      fetch("https://your_resource_name/getBalance", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.success) {
            this.balance = data.balance;
          } else {
            console.warn(data.message);
          }
        })
        .catch((error) => {
          console.error("Error fetching balance:", error);
        })
        .finally(() => {
          this.loading = false;
        });
    },
    deposit() {
      if (this.amount > 0) {
        this.loading = true;
        fetch("https://your_resource_name/deposit", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ amount: this.amount }),
        })
          .then((response) => response.json())
          .then((data) => {
            if (data.success) {
              this.balance = data.newBalance;
              this.message = "";
            } else {
              this.message = data.message;
            }
          })
          .finally(() => {
            this.loading = false;
          });
      } else {
        this.message = "Please enter a valid amount";
      }
      this.amount = "";
    },
    withdraw() {
      if (this.amount > 0) {
        this.loading = true;
        fetch("https://your_resource_name/withdraw", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ amount: this.amount }),
        })
          .then((response) => response.json())
          .then((data) => {
            if (data.success) {
              this.balance = data.newBalance;
              this.message = "";
            } else {
              this.message = data.message;
            }
          })
          .finally(() => {
            this.loading = false;
          });
      } else {
        this.message = "Please enter a valid amount";
      }
      this.amount = "";
    },
    showHistory() {
      this.loading = true;
      fetch("https://your_resource_name/history", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.success) {
            this.history = data.history;
            this.currentView = "history";
          } else {
            this.message = data.message;
          }
        })
        .catch((error) => {
          console.error("Error fetching history:", error);
          this.message = "Failed to fetch history.";
          this.history = [
            { date: "2024-01-01", type: "Deposit", amount: 100 },
            { date: "2023-01-02", type: "Withdraw", amount: 50 },
            { date: "2023-01-03", type: "Deposit", amount: 200 },
            { date: "2023-01-04", type: "Withdraw", amount: 30 },
            { date: "2023-01-05", type: "Deposit", amount: 150 },
            { date: "2023-01-06", type: "Withdraw", amount: 70 },
            { date: "2023-01-07", type: "Deposit", amount: 300 },
            { date: "2023-01-08", type: "Withdraw", amount: 90 },
            { date: "2023-01-09", type: "Deposit", amount: 400 },
            { date: "2023-01-10", type: "Withdraw", amount: 100 },
            { date: "2023-01-11", type: "Deposit", amount: 500 },
            { date: "2023-01-12", type: "Withdraw", amount: 120 },
          ];
          this.currentView = "history";
        })
        .finally(() => {
          this.loading = false;
        });
    },
    goBack() {
      this.currentView = "main";
    },
  },
};
</script>

<style scoped>
.loading-square {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 100px;
  height: 100px;
  background-color: rgba(0, 0, 0, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 10px;
}

.loading-animation {
  position: relative;
  width: 50px;
  height: 50px;
}

.line {
  position: absolute;
  width: 100%;
  height: 100%;
  border: 2px solid #00f9b9;
  border-radius: 10px;
  animation: spin 1s linear infinite;
}

.line1 {
  animation-delay: 0s;
}
.line2 {
  animation-delay: 0.25s;
}
.line3 {
  animation-delay: 0.5s;
}
.line4 {
  animation-delay: 0.75s;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
