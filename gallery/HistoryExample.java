// @start:basics
public class Account {
	private double balance;

	public Konto(double balance) {
		this.balance = balance;
	}

// @start:mutators
	public void deposit(double amount) {
		this.balance += amount;
	}

	public boolean withdraw(double amount) {
		if(this.balance - amount >= 0) {
			this.balance -= amount;
			return true;
		}
		return false;
	}

// @end:mutators
	public double getBalance() {
		return this.balance;
	}
}
// @end:basics
// extra
