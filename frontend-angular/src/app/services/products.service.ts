import { Injectable, Inject, PLATFORM_ID } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { BehaviorSubject, Observable, of, catchError, map } from 'rxjs';
import { Product } from '../models/product.model';
import { isPlatformBrowser } from '@angular/common';
import { environment } from '../../environments/environment';

interface ProductResponse {
  id: number;
  name: string;
  description: string;
  price: number;
  stockQuantity: number;
  categoryId: number;
  categoryName: string;
  imageFilename: string | null;
  isOrganic: boolean;
  certifications: string | null;
  originCountry: string | null;
  carbonFootprint: number | null;
  isActive: boolean;
  isFeatured: boolean;
  createdAt?: string;
  updatedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ProductsService {
  private readonly API_URL = `${environment.apiUrl.replace(/\/+$/, '')}/products`;
  private products: Product[] = [];
  private productsSubject = new BehaviorSubject<Product[]>(this.products);
  public products$ = this.productsSubject.asObservable();

  constructor(private http: HttpClient, @Inject(PLATFORM_ID) private platformId: Object) {
    // Only load products automatically when running in the browser.
    // This prevents SSR/build-time attempts to contact localhost (which fail on Vercel).
    if (isPlatformBrowser(this.platformId)) {
      this.loadProducts();
    }
  }

  private loadProducts(): void {
    this.http.get<ProductResponse[]>(this.API_URL).pipe(
      catchError((error) => {
        console.error('Error loading products:', error);
        return of([]);
      }),
      map((response: ProductResponse[]) => response.map(this.mapToProduct.bind(this)))
    ).subscribe((products: Product[]) => {
      this.products = products;
      this.productsSubject.next([...this.products]);
    });
  }

  getProducts(): Observable<Product[]> {
    return this.http.get<ProductResponse[]>(this.API_URL).pipe(
      catchError((error) => {
        console.error('Error getting products:', error);
        return of([]);
      }),
      map((response: ProductResponse[]) => response.map(this.mapToProduct.bind(this)))
    );
  }

  getProductById(id: number): Observable<Product | undefined> {
    return this.http.get<ProductResponse>(`${this.API_URL}/${id}`).pipe(
      catchError((error) => {
        console.error('Error getting product by id:', error);
        return of(undefined);
      }),
      map((response: ProductResponse | undefined) => response ? this.mapToProduct(response) : undefined)
    );
  }

  getProductsByCategory(categoryName: string): Observable<Product[]> {
    return this.http.get<ProductResponse[]>(this.API_URL, {
      params: new HttpParams().set('category', categoryName)
    }).pipe(
      catchError((error) => {
        console.error('Error getting products by category:', error);
        return of([]);
      }),
      map((response: ProductResponse[]) => response.map(this.mapToProduct.bind(this)))
    );
  }

  searchProducts(query: string): Observable<Product[]> {
    return this.http.get<ProductResponse[]>(`${this.API_URL}/search`, {
      params: new HttpParams().set('keyword', query)
    }).pipe(
      catchError((error) => {
        console.error('Error searching products:', error);
        return of([]);
      }),
      map((response: ProductResponse[]) => response.map(this.mapToProduct.bind(this)))
    );
  }

  getFeatured(): Product[] {
    return this.products.slice(0, 3);
  }

  getCategories(): string[] {
    return [...new Set(this.products.map(p => p.categoryName))];
  }

  private mapToProduct(response: ProductResponse): Product {
    // URL placeholder basado en la categoría del producto
    const placeholders: { [key: string]: string } = {
      'Muebles Ecológicos': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400&h=300&fit=crop',
      'Accesorios Sostenibles': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&h=300&fit=crop',
      'Hogar Eco-Friendly': 'https://images.unsplash.com/photo-1484101403633-562f891dc89a?w=400&h=300&fit=crop',
      'default': 'https://images.unsplash.com/photo-1532453288672-3a27e9be9efd?w=400&h=300&fit=crop'
    };

    const imageUrl = response.imageFilename
      ? `${environment.apiUrl.replace(/\/+$/, '')}/images/${response.imageFilename}`
      : (placeholders[response.categoryName] || placeholders['default']);

    return {
      id: response.id,
      name: response.name,
      description: response.description,
      price: response.price,
      stock: response.stockQuantity,
      categoryId: response.categoryId,
      categoryName: response.categoryName,
      imageFilename: response.imageFilename,
      imageUrl: imageUrl,
      isOrganic: response.isOrganic,
      certifications: response.certifications,
      originCountry: response.originCountry,
      carbonFootprint: response.carbonFootprint ?? undefined,
      createdAt: new Date(),
      updatedAt: new Date(),
      // Aliases para compatibilidad
      category: response.categoryName,
      inStock: response.stockQuantity > 0,
      tags: [], // Inicializar tags como array vacío
      ecoRating: 3, // Valor por defecto
      sustainabilityScore: 80 // Valor por defecto
    };
  }

  // --- Minimal create/update/delete implementations used by admin components ---
  createProduct(product: Omit<Product, 'id' | 'createdAt' | 'updatedAt'>): Observable<Product> {
    const newProduct: Product = {
      ...product as Product,
      id: Date.now(),
      createdAt: new Date(),
      updatedAt: new Date(),
      // ensure aliases
      category: (product as any).category || product.categoryName,
      inStock: (product as any).inStock ?? (product.stock > 0),
    };
    this.products.push(newProduct);
    this.productsSubject.next([...this.products]);
    return of(newProduct);
  }

  updateProduct(id: number, updates: Partial<Product>): Observable<Product | null> {
    const index = this.products.findIndex(p => p.id === id);
    if (index === -1) return of(null);
    const updated = { ...this.products[index], ...updates, updatedAt: new Date() } as Product;
    this.products[index] = updated;
    this.productsSubject.next([...this.products]);
    return of(updated);
  }

  deleteProduct(id: number): Observable<boolean> {
    const index = this.products.findIndex(p => p.id === id);
    if (index === -1) return of(false);
    this.products.splice(index, 1);
    this.productsSubject.next([...this.products]);
    return of(true);
  }

  private mapToProductResponse(product: Product): ProductResponse {
    const toIsoString = (value: string | Date) => new Date(value).toISOString();
    // Minimal mapping for fallback/mock usage
    return {
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      stockQuantity: product.stock,
      categoryId: product.categoryId ?? 0,
      categoryName: product.categoryName ?? product.category ?? '',
      imageFilename: product.imageFilename ?? null,
      isOrganic: product.isOrganic ?? false,
      certifications: product.certifications ?? null,
      originCountry: product.originCountry ?? null,
      carbonFootprint: product.carbonFootprint ?? null,
      isActive: true,
      isFeatured: false,
      createdAt: toIsoString(product.createdAt),
      updatedAt: toIsoString(product.updatedAt),
    };
  }
}

