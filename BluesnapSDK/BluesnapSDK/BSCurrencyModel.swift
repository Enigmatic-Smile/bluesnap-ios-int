import Foundation

public class BSCurrency {
    
    internal var name : String!
    internal var code : String!
    internal var rate: Double!
    
    internal init(name: String!, code: String!, rate: Double!) {
        self.name = name
        self.code = code
        self.rate = rate
    }
    
    public func getName() -> String! {
        return self.name
    }
    
    public func getCode() -> String! {
        return self.code
    }
    
    public func getRate() -> Double! {
        return self.rate
    }
    
}

public class BSCurrencies {
    
    internal var currencies = Array<BSCurrency!>()

    
    internal init(currencies : Array<BSCurrency>) {
        
        self.currencies = currencies
    }
    
    public func getCurrencyByCode(code : String!) -> BSCurrency? {
        
        for currency in currencies {
            if currency!.code == code {
                return currency
            }
        }
        return nil
    }
    
    public func getCurrencyRateByCurrencyCode(code : String!) -> Double? {
        
        return getCurrencyByCode(code: code)?.rate
    }
}
