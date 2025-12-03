import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators, FormArray } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { Product } from '../../../models/product.model';
import { ProductsService } from '../../../services/products.service';

@Component({
  selector: 'app-admin-product-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './admin-product-form.component.html',
  styleUrls: ['./admin-product-form.component.scss']
})
export class AdminProductFormComponent implements OnInit, OnDestroy {
  productForm!: FormGroup;
  isEditMode = false;
  productId: number | null = null;
  isLoading = false;
  isSubmitting = false;
  categories: string[] = [];
  availableTags: string[] = [
    'reciclado', 'ecológico', 'biodegradable', 'orgánico', 'vegano',
    'sostenible', 'reutilizable', 'certificado', 'natural', 'artesanal',
    'madera reciclada', 'plástico reciclado', 'cuero vegano', 'algodón orgánico',
    'acero inoxidable', 'juguete', 'educativo', 'bolsa', 'cartera', 'maceta',
    'botella', 'camiseta'
  ];
  selectedImageFile: File | null = null;
  imagePreview: string | null = null;

  private destroy$ = new Subject<void>();

  constructor(
    private fb: FormBuilder,
    private productsService: ProductsService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.initializeForm();
  }

  ngOnInit(): void {
    this.loadCategories();
    this.checkEditMode();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private initializeForm(): void {
    this.productForm = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(100)]],
      description: ['', [Validators.required, Validators.minLength(10), Validators.maxLength(1000)]],
      price: ['', [Validators.required, Validators.min(0.01)]],
      category: ['', Validators.required],
      ecoRating: [3, [Validators.required, Validators.min(1), Validators.max(5)]],
      sustainabilityScore: [80, [Validators.required, Validators.min(0), Validators.max(100)]],
      carbonFootprint: [1.0, [Validators.required, Validators.min(0)]],
      tags: this.fb.array([]),
      inStock: [true, Validators.required],
      imageUrl: ['', [Validators.required, Validators.pattern(/^https?:\/\/.+/)]]
    });
  }

  private loadCategories(): void {
    this.categories = this.productsService.getCategories();
  }

  private checkEditMode(): void {
    const id = this.route.snapshot.params['id'];
    if (id) {
      this.isEditMode = true;
      this.productId = +id;
      this.loadProduct(this.productId);
    }
  }

  private loadProduct(id: number): void {
    this.isLoading = true;
    this.productsService.getProductById(id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (product: Product) => {
          if (product) {
            this.populateForm(product);
          } else {
            this.router.navigate(['/admin/products']);
          }
          this.isLoading = false;
        },
        error: (error: any) => {
          console.error('Error loading product:', error);
          this.isLoading = false;
          this.router.navigate(['/admin/products']);
        }
      });
  }

  private populateForm(product: Product): void {
    this.productForm.patchValue({
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      ecoRating: product.ecoRating,
      sustainabilityScore: product.sustainabilityScore,
      carbonFootprint: product.carbonFootprint,
      inStock: product.inStock,
      imageUrl: product.imageUrl
    });

    // Populate tags
    const tagsFormArray = this.productForm.get('tags') as FormArray;
    tagsFormArray.clear();
    if (product.tags && Array.isArray(product.tags)) {
      product.tags.forEach(tag => {
        tagsFormArray.push(this.fb.control(tag));
      });
    }

    // Set image preview
    this.imagePreview = product.imageUrl;
  }

  onImageFileSelected(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) {
      this.selectedImageFile = file;

      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        this.imagePreview = e.target?.result as string;
      };
      reader.readAsDataURL(file);

      // In a real app, you would upload the file to a server
      // For now, we'll use a placeholder URL
      this.productForm.patchValue({
        imageUrl: 'https://via.placeholder.com/400x300?text=Uploaded+Image'
      });
    }
  }

  addTag(tag: string): void {
    const tagsFormArray = this.productForm.get('tags') as FormArray;
    if (!tagsFormArray.value.includes(tag)) {
      tagsFormArray.push(this.fb.control(tag));
    }
  }

  removeTag(index: number): void {
    const tagsFormArray = this.productForm.get('tags') as FormArray;
    tagsFormArray.removeAt(index);
  }

  onSubmit(): void {
    if (this.productForm.valid) {
      this.isSubmitting = true;

      const formValue = this.productForm.value;
      const productData = {
        ...formValue,
        tags: formValue.tags || []
      };

      const operation = this.isEditMode
        ? this.productsService.updateProduct(this.productId!, productData)
        : this.productsService.createProduct(productData);

      operation.pipe(takeUntil(this.destroy$)).subscribe({
        next: (result: Product | null) => {
          this.isSubmitting = false;
          if (result) {
            this.router.navigate(['/admin/products']);
          }
        },
        error: (error: any) => {
          console.error('Error saving product:', error);
          this.isSubmitting = false;
        }
      });
    } else {
      this.markFormGroupTouched();
    }
  }

  onCancel(): void {
    this.router.navigate(['/admin/products']);
  }

  private markFormGroupTouched(): void {
    Object.keys(this.productForm.controls).forEach(key => {
      const control = this.productForm.get(key);
      control?.markAsTouched();
    });
  }

  get tagsFormArray(): FormArray {
    return this.productForm.get('tags') as FormArray;
  }

  getFieldError(fieldName: string): string {
    const field = this.productForm.get(fieldName);
    if (field?.errors && field.touched) {
      if (field.errors['required']) {
        return `${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)} es requerido`;
      }
      if (field.errors['minlength']) {
        return `${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)} debe tener al menos ${field.errors['minlength'].requiredLength} caracteres`;
      }
      if (field.errors['maxlength']) {
        return `${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)} no puede exceder ${field.errors['maxlength'].requiredLength} caracteres`;
      }
      if (field.errors['min']) {
        return `${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)} debe ser mayor a ${field.errors['min'].min}`;
      }
      if (field.errors['max']) {
        return `${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)} debe ser menor o igual a ${field.errors['max'].max}`;
      }
      if (field.errors['pattern']) {
        return 'URL inválida';
      }
    }
    return '';
  }

  // Getters for template
  get name() { return this.productForm.get('name'); }
  get description() { return this.productForm.get('description'); }
  get category() { return this.productForm.get('category'); }
  get price() { return this.productForm.get('price'); }
  get imageUrl() { return this.productForm.get('imageUrl'); }
  get carbonFootprint() { return this.productForm.get('carbonFootprint'); }
  get sustainabilityScore() { return this.productForm.get('sustainabilityScore'); }
  get ecoRating() { return this.productForm.get('ecoRating'); }
}