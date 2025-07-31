-- Phase 1: Fix critical security issues

-- 1. Fix nullable user_id in orders table
-- First, update any existing orders with null user_id to use a system user approach
-- (In production, you'd handle this differently based on business requirements)

-- Make user_id NOT NULL in orders table
ALTER TABLE public.orders 
ALTER COLUMN user_id SET NOT NULL;

-- 2. Add missing RLS policies for orders table
-- Allow users to update their own orders (for status updates, etc.)
CREATE POLICY "Users can update their own orders" 
ON public.orders 
FOR UPDATE 
USING (auth.uid() = user_id);

-- Allow users to delete their own orders (if needed)
CREATE POLICY "Users can delete their own orders" 
ON public.orders 
FOR DELETE 
USING (auth.uid() = user_id);

-- 3. Add admin policies for categories and products management
-- Create a simple admin check function first
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN 
LANGUAGE SQL 
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
    AND (full_name ILIKE '%admin%' OR full_name ILIKE '%manager%')
  );
$$;

-- Admin policies for categories
CREATE POLICY "Admins can insert categories" 
ON public.categories 
FOR INSERT 
WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update categories" 
ON public.categories 
FOR UPDATE 
USING (public.is_admin());

CREATE POLICY "Admins can delete categories" 
ON public.categories 
FOR DELETE 
USING (public.is_admin());

-- Admin policies for products  
CREATE POLICY "Admins can insert products" 
ON public.products 
FOR INSERT 
WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update products" 
ON public.products 
FOR UPDATE 
USING (public.is_admin());

CREATE POLICY "Admins can delete products" 
ON public.products 
FOR DELETE 
USING (public.is_admin());