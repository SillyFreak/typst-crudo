// @region start:all start:basics
public class Account {
	private double balance;

	public Konto(double balance) {
		this.balance = balance;
	}

// @region end:basics start:mutators
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

// @region end:mutators start:basics
	public double getBalance() {
		return this.balance;
	}
}
// @region end:basics end:all
// extra
