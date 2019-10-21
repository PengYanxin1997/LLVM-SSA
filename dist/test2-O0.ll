; ModuleID = 'test.c'
source_filename = "test.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @f(i32 %0, i32 %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca double, align 8
  %6 = alloca i32, align 4
  store i32 %0, i32* %3, align 4
  store i32 %1, i32* %4, align 4
  store double 5.500000e+00, double* %5, align 8
  %7 = load i32, i32* %3, align 4
  %8 = load i32, i32* %4, align 4
  %9 = icmp sgt i32 %7, %8
  br i1 %9, label %10, label %13

10:                                               ; preds = %2
  %11 = load i32, i32* %3, align 4
  %12 = sitofp i32 %11 to double
  store double %12, double* %5, align 8
  br label %16

13:                                               ; preds = %2
  %14 = load i32, i32* %4, align 4
  %15 = sitofp i32 %14 to double
  store double %15, double* %5, align 8
  br label %16

16:                                               ; preds = %13, %10
  store i32 5, i32* %6, align 4
  %17 = load i32, i32* %6, align 4
  %18 = sitofp i32 %17 to double
  %19 = load double, double* %5, align 8
  %20 = fcmp ogt double %18, %19
  br i1 %20, label %21, label %24

21:                                               ; preds = %16
  %22 = load i32, i32* %6, align 4
  %23 = sitofp i32 %22 to double
  store double %23, double* %5, align 8
  br label %25

24:                                               ; preds = %16
  store double -1.000000e+00, double* %5, align 8
  br label %25

25:                                               ; preds = %24, %21
  %26 = load double, double* %5, align 8
  %27 = fptosi double %26 to i32
  ret i32 %27
}

attributes #0 = { noinline nounwind optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 10.0.0 "}
