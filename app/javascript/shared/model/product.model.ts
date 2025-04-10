export interface Product {
    id: number;
    selected: boolean;
    name: string;
    category: string;
    sales: number;
    unitPrice: number;
    quantity: number;
    status: "active" | "inactive"; 
    description: string;
}
