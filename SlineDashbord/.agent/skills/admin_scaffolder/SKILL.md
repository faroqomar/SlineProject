---
description: Automates the creation of strict MVVM features for the Admin Dashboard
---

# Admin Feature Scaffolder

**Goal**: Create a new feature module with the strict strict file structure and boilerplate code required by `admin-architecture.mdc`.

## Instructions

When asked to "create a feature" or "scaffold [feature_name]", follow these steps:

1.  **Create Directory Structure**:
    Inside `sline_admin/app/features/[feature_name]/`, create:
    *   `models/`
    *   `services/`
    *   `viewmodels/`
    *   `view/`

2.  **Generate Files (Standard Naming)**:

    **A. Model (`models/[feature].model.ts`)**
    ```typescript
    export interface [Feature] {
      id: string;
      createdAt: string;
      // Add fields based on instruction
    }
    ```

    **B. Schema (`models/[feature].schema.ts`)**
    ```typescript
    import { z } from 'zod';

    export const [Feature]IdSchema = z.string().uuid();
    export const Create[Feature]Schema = z.object({
       // Add fields
    });
    ```

    **C. Service (`services/[feature].service.ts`)**
    ```typescript
    'use server'
    import { createServiceRoleClient } from '@/lib/supabase/server';
    import { ActionResult } from '@/types/action-result';
    import { [Feature]IdSchema } from '../models/[feature].schema';

    export async function fetch[Feature](id: string): Promise<ActionResult<any>> {
      // 1. Validation
      const parsed = [Feature]IdSchema.safeParse(id);
      if (!parsed.success) return { success: false, error: { code: 'INVALID_INPUT', message: 'Invalid ID' } };

      // 2. Auth Check
      // ... verifyAdminRole() ...

      // 3. Logic
      const supabase = await createServiceRoleClient();
      // ... query ...
      
      return { success: true, data: {} };
    }
    ```

    **D. ViewModel (`viewmodels/use_[feature]_list.vm.ts`)**
    ```typescript
    'use client'
    import { useState, useEffect } from 'react';
    import { [Feature]Service } from '../services/[feature].service';

    export function use[Feature]ListVM() {
      const [state, setState] = useState([]);
      const [isLoading, setIsLoading] = useState(false);

      useEffect(() => { load(); }, []);

      const load = async () => {
         setIsLoading(true);
         const res = await [Feature]Service.fetchAll();
         if (res.success) setState(res.data);
         setIsLoading(false);
      };

      return { items: state, isLoading, load };
    }
    ```

    **E. View (`view/[feature]_list.view.tsx`)**
    ```tsx
    'use client'
    import { use[Feature]ListVM } from '../viewmodels/use_[feature]_list.vm';

    export function [Feature]ListView() {
      const { items, isLoading } = use[Feature]ListVM();
      
      if (isLoading) return <div>Loading...</div>;
      
      return (
        <div className="p-4">
           {/* DataTable here */}
        </div>
      );
    }
    ```
