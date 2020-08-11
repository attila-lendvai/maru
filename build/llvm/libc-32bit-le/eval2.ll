%word = type i32
%ptr = type i8*
define %ptr @max(%ptr %a, %ptr %b) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %a, %ptr* %t1
	store %ptr %b, %ptr* %t2
	%r1 = load %ptr, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = icmp sgt %word %r6, %r5
	%r3 = inttoptr i1 %r4 to %ptr
	%r8 = ptrtoint %ptr %r3 to %word
	%r7 = icmp ne %word %r8, 0
	br i1 %r7, label %L1, label %L2
L1:
	%r9 = load %ptr, %ptr* %t1
	store %ptr %r9, %ptr* %t3
	br label %L3
L2:
	%r10 = load %ptr, %ptr* %t2
	store %ptr %r10, %ptr* %t3
	br label %L3
L3:
	%r11 = load %ptr, %ptr* %t3
	ret %ptr %r11
}
declare void @abort()
declare void @exit(i32)
declare %ptr @malloc(i32)
declare void @free(%ptr)
declare %ptr @realloc(%ptr, i32)
declare %ptr @memset(%ptr, i32, i32)
declare %ptr @memcpy(%ptr, %ptr, i32)
declare %ptr @memmove(%ptr, %ptr, i32)
declare i32 @printf(%ptr, ...)
declare i32 @fprintf(%ptr, %ptr, ...)
declare i32 @sprintf(%ptr, %ptr, ...)
declare i32 @snprintf(%ptr, i32, %ptr, ...)
declare i32 @puts(%ptr)
declare i32 @fputc(%ptr, %ptr)
declare i32 @fgetc(%ptr)
declare i32 @ungetc(i32, %ptr)
declare %ptr @fopen(%ptr, %ptr)
declare %ptr @fdopen(i32, %ptr)
declare i32 @fclose(%ptr)
declare i32 @fflush(%ptr)
declare i32 @fscanf(%ptr, %ptr, ...)
declare i32 @feof(%ptr)
declare void @setbuf(%ptr, %ptr)
declare i32 @strlen(%ptr)
declare %ptr @strcpy(%ptr, %ptr)
declare %ptr @strncpy(%ptr, %ptr, i32)
declare i32 @strcmp(%ptr, %ptr)
declare i32 @strncmp(%ptr, %ptr, i32)
declare %ptr @strdup(%ptr)
declare i32 @strtoul(%ptr, %ptr, i32)
define %ptr @"libc/flush-streams"() {
	%r1 = load %ptr, %ptr* @"libc/stdout"
	%r2 = call i32 @fflush(%ptr %r1)
	%r3 = inttoptr %word %r2 to %ptr
	%r4 = load %ptr, %ptr* @"libc/stderr"
	%r5 = call i32 @fflush(%ptr %r4)
	%r6 = inttoptr %word %r5 to %ptr
	ret %ptr %r6
}
define %ptr @"k/print"(%ptr %obj) {
	%t1 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = inttoptr %word 0 to %ptr
	%r3 = call %ptr @do_print(%ptr %r1, %ptr %r2)
	ret %ptr %r3
}
@str7 = private unnamed_addr constant [6 x i8] c"%3d: \00"
define %ptr @print-backtrace() {
	%t1 = alloca %ptr
	%r1 = load %ptr, %ptr* @"*backtrace-index*"
	store %ptr %r1, %ptr* %t1
	br label %L5
L4:
	%r2 = getelementptr [6 x i8], [6 x i8]* @str7, %word 0, %word 0
	%r4 = load %ptr, %ptr* %t1
	%r5 = call i32 (%ptr, ...) @printf(%ptr %r2, %ptr %r4)
	%r6 = inttoptr %word %r5 to %ptr
	%r7 = load %ptr, %ptr* @"*backtrace-stack*"
	%r8 = load %ptr, %ptr* %t1
	%r9 = call %ptr @"k/array-at"(%ptr %r7, %ptr %r8)
	%r10 = call %ptr @"k/dumpln"(%ptr %r9)
	%r11 = call %ptr @"libc/flush-streams"()
	br label %L5
L5:
	%r12 = inttoptr %word 1 to %ptr
	%r13 = load %ptr, %ptr* %t1
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = sub %word %r17, %r16
	%r14 = inttoptr %word %r15 to %ptr
	store %ptr %r14, %ptr* %t1
	%r18 = inttoptr %word 0 to %ptr
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = ptrtoint %ptr %r14 to %word
	%r20 = icmp sle %word %r22, %r21
	%r19 = inttoptr i1 %r20 to %ptr
	%r24 = ptrtoint %ptr %r19 to %word
	%r23 = icmp ne %word %r24, 0
	br i1 %r23, label %L4, label %L6
L6:
	ret %ptr %r19
}
@str8 = private unnamed_addr constant [89 x i8] c"\0ADIE called at depth %d, printing a backtrace to stdout and exiting with exit code 1...\0A\00"
define %ptr @die() {
	%r1 = load %ptr, %ptr* @"libc/stderr"
	%r2 = getelementptr [89 x i8], [89 x i8]* @str8, %word 0, %word 0
	%r4 = load %ptr, %ptr* @"*backtrace-index*"
	%r5 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r1, %ptr %r2, %ptr %r4)
	%r6 = inttoptr %word %r5 to %ptr
	%r7 = call %ptr @"libc/flush-streams"()
	%r8 = call %ptr @print-backtrace()
	%r9 = call %ptr @"libc/flush-streams"()
	call void @abort()
	%r11 = inttoptr %word 0 to %ptr
	ret %ptr %r11
}
@str9 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @fatal(%ptr %fmt) {
	%t1 = alloca %ptr
	store %ptr %fmt, %ptr* %t1
	%r1 = load %ptr, %ptr* @"libc/stderr"
	%r2 = load %ptr, %ptr* %t1
	%r3 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r1, %ptr %r2)
	%r4 = inttoptr %word %r3 to %ptr
	%r5 = load %ptr, %ptr* @"libc/stderr"
	%r6 = getelementptr [2 x i8], [2 x i8]* @str9, %word 0, %word 0
	%r8 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r5, %ptr %r6)
	%r9 = inttoptr %word %r8 to %ptr
	%r10 = call %ptr @die()
	ret %ptr %r10
}
@str10 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @fatal1(%ptr %fmt, %ptr %arg) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %fmt, %ptr* %t1
	store %ptr %arg, %ptr* %t2
	%r1 = load %ptr, %ptr* @"libc/stderr"
	%r2 = load %ptr, %ptr* %t1
	%r3 = load %ptr, %ptr* %t2
	%r4 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r1, %ptr %r2, %ptr %r3)
	%r5 = inttoptr %word %r4 to %ptr
	%r6 = load %ptr, %ptr* @"libc/stderr"
	%r7 = getelementptr [2 x i8], [2 x i8]* @str10, %word 0, %word 0
	%r9 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r6, %ptr %r7)
	%r10 = inttoptr %word %r9 to %ptr
	%r11 = call %ptr @die()
	ret %ptr %r11
}
@str11 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @fatal2(%ptr %fmt, %ptr %arg1, %ptr %arg2) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %fmt, %ptr* %t1
	store %ptr %arg1, %ptr* %t2
	store %ptr %arg2, %ptr* %t3
	%r1 = load %ptr, %ptr* @"libc/stderr"
	%r2 = load %ptr, %ptr* %t1
	%r3 = load %ptr, %ptr* %t2
	%r4 = load %ptr, %ptr* %t3
	%r5 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r1, %ptr %r2, %ptr %r3, %ptr %r4)
	%r6 = inttoptr %word %r5 to %ptr
	%r7 = load %ptr, %ptr* @"libc/stderr"
	%r8 = getelementptr [2 x i8], [2 x i8]* @str11, %word 0, %word 0
	%r10 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r7, %ptr %r8)
	%r11 = inttoptr %word %r10 to %ptr
	%r12 = call %ptr @die()
	ret %ptr %r12
}
@str24 = private unnamed_addr constant [56 x i8] c"get/type: encountered an unidentifiable immediate: {%p}\00"
@str25 = private unnamed_addr constant [53 x i8] c"get/type: encountered something unidentifiable: {%p}\00"
define %ptr @"get/type"(%ptr %_ptr_) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %_ptr_, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = icmp eq %word %r5, 0
	%r3 = zext i1 %r4 to %word
	%r2 = inttoptr %word %r3 to %ptr
	%r7 = ptrtoint %ptr %r2 to %word
	%r6 = icmp ne %word %r7, 0
	br i1 %r6, label %L12, label %L13
L12:
	%r8 = inttoptr %word 4 to %ptr
	store %ptr %r8, %ptr* %t2
	br label %L14
L13:
	%r9 = inttoptr %word 3 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = and %word %r14, %r13
	%r11 = inttoptr %word %r12 to %ptr
	%r15 = inttoptr %word 0 to %ptr
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = ptrtoint %ptr %r11 to %word
	%r17 = icmp eq %word %r19, %r18
	%r16 = inttoptr i1 %r17 to %ptr
	%r21 = ptrtoint %ptr %r16 to %word
	%r20 = icmp ne %word %r21, 0
	br i1 %r20, label %L15, label %L16
L15:
	%r22 = inttoptr %word 16 to %ptr
	%r23 = load %ptr, %ptr* %t1
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = sub %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	store %ptr %r24, %ptr* %t4
	%r28 = inttoptr %word 0 to %ptr
	%r29 = inttoptr %word 0 to %ptr
	%r30 = inttoptr %word 3 to %ptr
	%r31 = load %ptr, %ptr* %t4
	%r35 = bitcast %ptr %r31 to [0 x %ptr]*
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = getelementptr [0 x %ptr], [0 x %ptr]* %r35, %word 0, %word %r34
	%r32 = load %ptr, %ptr* %r33
	store %ptr %r32, %ptr* %t3
	br label %L17
L16:
	%r36 = inttoptr %word 3 to %ptr
	%r37 = load %ptr, %ptr* %t1
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = and %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r42 = inttoptr %word 0 to %ptr
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = icmp eq %word %r46, %r45
	%r43 = inttoptr i1 %r44 to %ptr
	%r50 = ptrtoint %ptr %r43 to %word
	%r49 = icmp eq %word %r50, 0
	%r48 = zext i1 %r49 to %word
	%r47 = inttoptr %word %r48 to %ptr
	%r52 = ptrtoint %ptr %r47 to %word
	%r51 = icmp ne %word %r52, 0
	br i1 %r51, label %L18, label %L19
L18:
	%r53 = inttoptr %word 1 to %ptr
	%r54 = load %ptr, %ptr* %t1
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = and %word %r58, %r57
	%r55 = inttoptr %word %r56 to %ptr
	%r59 = inttoptr %word 1 to %ptr
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = ptrtoint %ptr %r55 to %word
	%r61 = icmp eq %word %r63, %r62
	%r60 = inttoptr i1 %r61 to %ptr
	%r65 = ptrtoint %ptr %r60 to %word
	%r64 = icmp ne %word %r65, 0
	br i1 %r64, label %L21, label %L22
L21:
	%r66 = inttoptr %word 6 to %ptr
	store %ptr %r66, %ptr* %t5
	br label %L23
L22:
	%r67 = getelementptr [56 x i8], [56 x i8]* @str24, %word 0, %word 0
	%r69 = load %ptr, %ptr* %t1
	%r70 = call %ptr @fatal1(%ptr %r67, %ptr %r69)
	store %ptr %r70, %ptr* %t5
	br label %L23
L23:
	%r71 = load %ptr, %ptr* %t5
	store %ptr %r71, %ptr* %t4
	br label %L20
L19:
	%r72 = getelementptr [53 x i8], [53 x i8]* @str25, %word 0, %word 0
	%r74 = load %ptr, %ptr* %t1
	%r75 = call %ptr @fatal1(%ptr %r72, %ptr %r74)
	store %ptr %r75, %ptr* %t4
	br label %L20
L20:
	%r76 = load %ptr, %ptr* %t4
	store %ptr %r76, %ptr* %t3
	br label %L17
L17:
	%r77 = load %ptr, %ptr* %t3
	store %ptr %r77, %ptr* %t2
	br label %L14
L14:
	%r78 = load %ptr, %ptr* %t2
	ret %ptr %r78
}
@str28 = private unnamed_addr constant [55 x i8] c"kernel get/put type error: expected type id %d, got %d\00"
define %ptr @"%type-check"(%ptr %obj, %ptr %exp-type) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	store %ptr %exp-type, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"get/type"(%ptr %r1)
	store %ptr %r2, %ptr* %t3
	%r3 = inttoptr %word 0 to %ptr
	store %ptr %r3, %ptr* %t4
	%r4 = load %ptr, %ptr* %t3
	%r5 = load %ptr, %ptr* %t2
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	store %ptr %r6, %ptr* %t4
	%r10 = inttoptr %word 0 to %ptr
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = icmp eq %word %r14, %r13
	%r11 = inttoptr i1 %r12 to %ptr
	%r16 = ptrtoint %ptr %r11 to %word
	%r15 = icmp ne %word %r16, 0
	br i1 %r15, label %L27, label %L26
L27:
	%r17 = getelementptr [55 x i8], [55 x i8]* @str28, %word 0, %word 0
	%r19 = load %ptr, %ptr* %t2
	%r20 = load %ptr, %ptr* %t3
	%r21 = call %ptr @fatal2(%ptr %r17, %ptr %r19, %ptr %r20)
	store %ptr %r21, %ptr* %t4
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L29, label %L26
L29:
	br label %L26
L26:
	%r29 = load %ptr, %ptr* %t4
	ret %ptr %r29
}
@str32 = private unnamed_addr constant [14 x i8] c"out of memory\00"
@str36 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str37 = private unnamed_addr constant [63 x i8] c"gc/acquire-new-heap-space: aligned-to-oop? has failed for ptr \00"
@str38 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"gc/acquire-new-heap-space"(%ptr %size) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %size, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%ffi-cast2 = ptrtoint %ptr %r1 to i32
	%r3 = call %ptr @malloc(i32 %ffi-cast2)
	store %ptr %r3, %ptr* %t2
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t3
	%r5 = load %ptr, %ptr* %t2
	store %ptr %r5, %ptr* %t3
	%r6 = inttoptr %word 0 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = icmp ne %word %r12, 0
	br i1 %r11, label %L31, label %L30
L31:
	%r13 = getelementptr [14 x i8], [14 x i8]* @str32, %word 0, %word 0
	%r15 = call %ptr @fatal(%ptr %r13)
	store %ptr %r15, %ptr* %t3
	%r16 = inttoptr %word 0 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r22 = ptrtoint %ptr %r17 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L33, label %L30
L33:
	br label %L30
L30:
	%r23 = load %ptr, %ptr* %t3
	%r24 = inttoptr %word 16 to %ptr
	%r25 = load %ptr, %ptr* %t1
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = sub %word %r29, %r28
	%r26 = inttoptr %word %r27 to %ptr
	%r30 = inttoptr %word 0 to %ptr
	%r31 = load %ptr, %ptr* %t2
	%r35 = bitcast %ptr %r31 to [0 x %ptr]*
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = getelementptr [0 x %ptr], [0 x %ptr]* %r35, %word 0, %word %r34
	store %ptr %r26, %ptr* %r33
	%r32 = bitcast %ptr %r26 to %ptr
	%r36 = inttoptr %word 0 to %ptr
	%r37 = inttoptr %word 1 to %ptr
	%r38 = load %ptr, %ptr* %t2
	%r42 = bitcast %ptr %r38 to [0 x %ptr]*
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = getelementptr [0 x %ptr], [0 x %ptr]* %r42, %word 0, %word %r41
	store %ptr %r36, %ptr* %r40
	%r39 = bitcast %ptr %r36 to %ptr
	%r43 = load %ptr, %ptr* %t2
	%r44 = inttoptr %word 2 to %ptr
	%r45 = load %ptr, %ptr* %t2
	%r49 = bitcast %ptr %r45 to [0 x %ptr]*
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = getelementptr [0 x %ptr], [0 x %ptr]* %r49, %word 0, %word %r48
	store %ptr %r43, %ptr* %r47
	%r46 = bitcast %ptr %r43 to %ptr
	%r50 = inttoptr %word 0 to %ptr
	%r51 = inttoptr %word 0 to %ptr
	store %ptr %r51, %ptr* %t3
	%r52 = inttoptr %word 3 to %ptr
	%r53 = load %ptr, %ptr* %t2
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = and %word %r57, %r56
	%r54 = inttoptr %word %r55 to %ptr
	%r58 = inttoptr %word 0 to %ptr
	%r62 = ptrtoint %ptr %r58 to %word
	%r61 = ptrtoint %ptr %r54 to %word
	%r60 = icmp eq %word %r62, %r61
	%r59 = inttoptr i1 %r60 to %ptr
	store %ptr %r59, %ptr* %t3
	%r63 = inttoptr %word 0 to %ptr
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r59 to %word
	%r65 = icmp eq %word %r67, %r66
	%r64 = inttoptr i1 %r65 to %ptr
	%r69 = ptrtoint %ptr %r64 to %word
	%r68 = icmp ne %word %r69, 0
	br i1 %r68, label %L35, label %L34
L35:
	%r70 = getelementptr [9 x i8], [9 x i8]* @str36, %word 0, %word 0
	%r72 = call i32 (%ptr, ...) @printf(%ptr %r70)
	%r73 = inttoptr %word %r72 to %ptr
	%r74 = getelementptr [63 x i8], [63 x i8]* @str37, %word 0, %word 0
	%r76 = call i32 (%ptr, ...) @printf(%ptr %r74)
	%r77 = inttoptr %word %r76 to %ptr
	%r78 = load %ptr, %ptr* %t2
	%r79 = call %ptr @"k/print"(%ptr %r78)
	%r80 = getelementptr [2 x i8], [2 x i8]* @str38, %word 0, %word 0
	%r82 = call i32 (%ptr, ...) @printf(%ptr %r80)
	%r83 = inttoptr %word %r82 to %ptr
	%r84 = call %ptr @die()
	store %ptr %r84, %ptr* %t3
	%r85 = inttoptr %word 0 to %ptr
	%r89 = ptrtoint %ptr %r85 to %word
	%r88 = ptrtoint %ptr %r84 to %word
	%r87 = icmp eq %word %r89, %r88
	%r86 = inttoptr i1 %r87 to %ptr
	%r91 = ptrtoint %ptr %r86 to %word
	%r90 = icmp ne %word %r91, 0
	br i1 %r90, label %L39, label %L34
L39:
	br label %L34
L34:
	%r92 = load %ptr, %ptr* %t3
	%r93 = load %ptr, %ptr* %t2
	ret %ptr %r93
}
define %ptr @"gc/initialise"() {
	%t1 = alloca %ptr
	%r1 = load %ptr, %ptr* @"gc/quantum"
	%r2 = call %ptr @"gc/acquire-new-heap-space"(%ptr %r1)
	store %ptr %r2, %ptr* %t1
	%r3 = load %ptr, %ptr* %t1
	store %ptr %r3, %ptr* @"gc/memory-base"
	%r4 = load %ptr, %ptr* %t1
	store %ptr %r4, %ptr* @"gc/memory-last"
	ret %ptr %r4
}
define %ptr @"gc/push-root"(%ptr %_ptr_) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %_ptr_, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t2
	%r3 = load %ptr, %ptr* @"gc/root-max"
	%r4 = load %ptr, %ptr* @"gc/root-count"
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	store %ptr %r5, %ptr* %t2
	%r9 = inttoptr %word 0 to %ptr
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = ptrtoint %ptr %r5 to %word
	%r11 = icmp eq %word %r13, %r12
	%r10 = inttoptr i1 %r11 to %ptr
	%r15 = ptrtoint %ptr %r10 to %word
	%r14 = icmp ne %word %r15, 0
	br i1 %r14, label %L40, label %L41
L41:
	%r16 = inttoptr %word 4 to %ptr
	%r17 = inttoptr %word 32 to %ptr
	%r18 = load %ptr, %ptr* @"gc/root-max"
	%r19 = inttoptr %word 2 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = mul %word %r23, %r22
	%r20 = inttoptr %word %r21 to %ptr
	%r24 = call %ptr @max(%ptr %r17, %ptr %r20)
	store %ptr %r24, %ptr* @"gc/root-max"
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = ptrtoint %ptr %r16 to %word
	%r26 = mul %word %r28, %r27
	%r25 = inttoptr %word %r26 to %ptr
	%ffi-cast29 = ptrtoint %ptr %r25 to i32
	%r30 = call %ptr @malloc(i32 %ffi-cast29)
	store %ptr %r30, %ptr* %t3
	%r31 = load %ptr, %ptr* %t3
	%r32 = load %ptr, %ptr* @"gc/roots"
	%r33 = inttoptr %word 4 to %ptr
	%r34 = load %ptr, %ptr* @"gc/root-count"
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r33 to %word
	%r36 = mul %word %r38, %r37
	%r35 = inttoptr %word %r36 to %ptr
	%ffi-cast39 = ptrtoint %ptr %r35 to i32
	%r40 = call %ptr @memcpy(%ptr %r31, %ptr %r32, i32 %ffi-cast39)
	%r41 = inttoptr %word 1 to %ptr
	store %ptr %r41, %ptr* %t4
	%r42 = load %ptr, %ptr* @"gc/roots"
	store %ptr %r42, %ptr* %t4
	%r43 = inttoptr %word 0 to %ptr
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = icmp eq %word %r47, %r46
	%r44 = inttoptr i1 %r45 to %ptr
	%r49 = ptrtoint %ptr %r44 to %word
	%r48 = icmp ne %word %r49, 0
	br i1 %r48, label %L42, label %L43
L43:
	%r50 = load %ptr, %ptr* @"gc/roots"
	call void @free(%ptr %r50)
	%r52 = inttoptr %word 0 to %ptr
	store %ptr %r52, %ptr* %t4
	%r53 = inttoptr %word 0 to %ptr
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = icmp eq %word %r57, %r56
	%r54 = inttoptr i1 %r55 to %ptr
	%r59 = ptrtoint %ptr %r54 to %word
	%r58 = icmp ne %word %r59, 0
	br i1 %r58, label %L42, label %L44
L44:
	br label %L42
L42:
	%r60 = load %ptr, %ptr* %t4
	%r61 = load %ptr, %ptr* %t3
	store %ptr %r61, %ptr* @"gc/roots"
	store %ptr %r61, %ptr* %t2
	%r62 = inttoptr %word 0 to %ptr
	%r66 = ptrtoint %ptr %r62 to %word
	%r65 = ptrtoint %ptr %r61 to %word
	%r64 = icmp eq %word %r66, %r65
	%r63 = inttoptr i1 %r64 to %ptr
	%r68 = ptrtoint %ptr %r63 to %word
	%r67 = icmp ne %word %r68, 0
	br i1 %r67, label %L40, label %L45
L45:
	br label %L40
L40:
	%r69 = load %ptr, %ptr* %t2
	%r70 = load %ptr, %ptr* %t1
	%r71 = load %ptr, %ptr* @"gc/root-count"
	%r72 = load %ptr, %ptr* @"gc/roots"
	%r76 = bitcast %ptr %r72 to [0 x %ptr]*
	%r75 = ptrtoint %ptr %r71 to %word
	%r74 = getelementptr [0 x %ptr], [0 x %ptr]* %r76, %word 0, %word %r75
	store %ptr %r70, %ptr* %r74
	%r73 = bitcast %ptr %r70 to %ptr
	%r77 = load %ptr, %ptr* @"gc/root-count"
	%r78 = inttoptr %word 1 to %ptr
	%r82 = ptrtoint %ptr %r78 to %word
	%r81 = ptrtoint %ptr %r77 to %word
	%r80 = add %word %r82, %r81
	%r79 = inttoptr %word %r80 to %ptr
	store %ptr %r79, %ptr* @"gc/root-count"
	ret %ptr %r79
}
@str48 = private unnamed_addr constant [21 x i8] c"root table underflow\00"
@str52 = private unnamed_addr constant [14 x i8] c"non-lifo root\00"
define %ptr @"gc/pop-root"(%ptr %_ptr_) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %_ptr_, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	store %ptr %r2, %ptr* %t2
	%r3 = load %ptr, %ptr* @"gc/root-count"
	store %ptr %r3, %ptr* %t2
	%r4 = inttoptr %word 0 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	%r10 = ptrtoint %ptr %r5 to %word
	%r9 = icmp ne %word %r10, 0
	br i1 %r9, label %L47, label %L46
L47:
	%r11 = getelementptr [21 x i8], [21 x i8]* @str48, %word 0, %word 0
	%r13 = call %ptr @fatal(%ptr %r11)
	store %ptr %r13, %ptr* %t2
	%r14 = inttoptr %word 0 to %ptr
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = icmp eq %word %r18, %r17
	%r15 = inttoptr i1 %r16 to %ptr
	%r20 = ptrtoint %ptr %r15 to %word
	%r19 = icmp ne %word %r20, 0
	br i1 %r19, label %L49, label %L46
L49:
	br label %L46
L46:
	%r21 = load %ptr, %ptr* %t2
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* @"gc/root-count"
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = sub %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	store %ptr %r24, %ptr* @"gc/root-count"
	%r28 = inttoptr %word 0 to %ptr
	store %ptr %r28, %ptr* %t2
	%r29 = load %ptr, %ptr* @"gc/root-count"
	%r30 = load %ptr, %ptr* @"gc/roots"
	%r34 = bitcast %ptr %r30 to [0 x %ptr]*
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = getelementptr [0 x %ptr], [0 x %ptr]* %r34, %word 0, %word %r33
	%r31 = load %ptr, %ptr* %r32
	%r35 = load %ptr, %ptr* %t1
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = ptrtoint %ptr %r31 to %word
	%r37 = icmp eq %word %r39, %r38
	%r36 = inttoptr i1 %r37 to %ptr
	store %ptr %r36, %ptr* %t2
	%r40 = inttoptr %word 0 to %ptr
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r36 to %word
	%r42 = icmp eq %word %r44, %r43
	%r41 = inttoptr i1 %r42 to %ptr
	%r46 = ptrtoint %ptr %r41 to %word
	%r45 = icmp ne %word %r46, 0
	br i1 %r45, label %L51, label %L50
L51:
	%r47 = getelementptr [14 x i8], [14 x i8]* @str52, %word 0, %word 0
	%r49 = call %ptr @fatal(%ptr %r47)
	store %ptr %r49, %ptr* %t2
	%r50 = inttoptr %word 0 to %ptr
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = ptrtoint %ptr %r49 to %word
	%r52 = icmp eq %word %r54, %r53
	%r51 = inttoptr i1 %r52 to %ptr
	%r56 = ptrtoint %ptr %r51 to %word
	%r55 = icmp ne %word %r56, 0
	br i1 %r55, label %L53, label %L50
L53:
	br label %L50
L50:
	%r57 = load %ptr, %ptr* %t2
	ret %ptr %r57
}
define %ptr @"gc/grow-heap"(%ptr %size) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %size, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"gc/acquire-new-heap-space"(%ptr %r1)
	store %ptr %r2, %ptr* %t2
	%r3 = inttoptr %word 2 to %ptr
	%r4 = load %ptr, %ptr* @"gc/memory-last"
	%r8 = bitcast %ptr %r4 to [0 x %ptr]*
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = getelementptr [0 x %ptr], [0 x %ptr]* %r8, %word 0, %word %r7
	%r5 = load %ptr, %ptr* %r6
	%r9 = inttoptr %word 2 to %ptr
	%r10 = load %ptr, %ptr* %t2
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	store %ptr %r5, %ptr* %r12
	%r11 = bitcast %ptr %r5 to %ptr
	%r15 = load %ptr, %ptr* %t2
	%r16 = inttoptr %word 2 to %ptr
	%r17 = load %ptr, %ptr* @"gc/memory-last"
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	store %ptr %r15, %ptr* %r19
	%r18 = bitcast %ptr %r15 to %ptr
	%r22 = load %ptr, %ptr* %t2
	ret %ptr %r22
}
define %ptr @"gc/object-size"(%ptr %obj) {
	%t1 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 16 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = sub %word %r7, %r6
	%r4 = inttoptr %word %r5 to %ptr
	%r11 = bitcast %ptr %r4 to [0 x %ptr]*
	%r10 = ptrtoint %ptr %r1 to %word
	%r9 = getelementptr [0 x %ptr], [0 x %ptr]* %r11, %word 0, %word %r10
	%r8 = load %ptr, %ptr* %r9
	ret %ptr %r8
}
define %ptr @"gc/sweep"() {
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* @"gc/memory-base"
	store %ptr %r2, %ptr* %t1
	%r3 = inttoptr %word 0 to %ptr
	store %ptr %r3, %ptr* %t2
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t3
	%r5 = inttoptr %word 0 to %ptr
	store %ptr %r5, %ptr* %t4
	br label %L55
L54:
	%r6 = inttoptr %word 1 to %ptr
	%r7 = load %ptr, %ptr* %t1
	%r11 = bitcast %ptr %r7 to [0 x %ptr]*
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = getelementptr [0 x %ptr], [0 x %ptr]* %r11, %word 0, %word %r10
	%r8 = load %ptr, %ptr* %r9
	store %ptr %r8, %ptr* %t5
	%r12 = inttoptr %word 4 to %ptr
	%r13 = load %ptr, %ptr* %t5
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = and %word %r17, %r16
	%r14 = inttoptr %word %r15 to %ptr
	%r19 = ptrtoint %ptr %r14 to %word
	%r18 = icmp ne %word %r19, 0
	br i1 %r18, label %L57, label %L58
L57:
	%r20 = inttoptr %word 0 to %ptr
	%r21 = inttoptr %word 0 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r27 = load %ptr, %ptr* %t3
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ptrtoint %ptr %r23 to %word
	%r29 = add %word %r31, %r30
	%r28 = inttoptr %word %r29 to %ptr
	store %ptr %r28, %ptr* %t3
	%r32 = inttoptr %word 1 to %ptr
	%r33 = load %ptr, %ptr* %t2
	%r37 = ptrtoint %ptr %r33 to %word
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = add %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	store %ptr %r34, %ptr* %t2
	%r38 = inttoptr %word 4 to %ptr
	%r39 = load %ptr, %ptr* %t5
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = xor %word %r43, %r42
	%r40 = inttoptr %word %r41 to %ptr
	%r44 = inttoptr %word 1 to %ptr
	%r45 = load %ptr, %ptr* %t1
	%r49 = bitcast %ptr %r45 to [0 x %ptr]*
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = getelementptr [0 x %ptr], [0 x %ptr]* %r49, %word 0, %word %r48
	store %ptr %r40, %ptr* %r47
	%r46 = bitcast %ptr %r40 to %ptr
	store %ptr %r46, %ptr* %t6
	br label %L59
L58:
	%r50 = inttoptr %word 0 to %ptr
	%r51 = inttoptr %word 0 to %ptr
	%r52 = load %ptr, %ptr* %t1
	%r56 = bitcast %ptr %r52 to [0 x %ptr]*
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = getelementptr [0 x %ptr], [0 x %ptr]* %r56, %word 0, %word %r55
	%r53 = load %ptr, %ptr* %r54
	%r57 = load %ptr, %ptr* %t4
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r53 to %word
	%r59 = add %word %r61, %r60
	%r58 = inttoptr %word %r59 to %ptr
	store %ptr %r58, %ptr* %t4
	%r62 = inttoptr %word 0 to %ptr
	%r63 = inttoptr %word 1 to %ptr
	%r64 = load %ptr, %ptr* %t1
	%r68 = bitcast %ptr %r64 to [0 x %ptr]*
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = getelementptr [0 x %ptr], [0 x %ptr]* %r68, %word 0, %word %r67
	store %ptr %r62, %ptr* %r66
	%r65 = bitcast %ptr %r62 to %ptr
	%r69 = inttoptr %word 0 to %ptr
	%r70 = inttoptr %word 3 to %ptr
	%r71 = load %ptr, %ptr* %t1
	%r75 = bitcast %ptr %r71 to [0 x %ptr]*
	%r74 = ptrtoint %ptr %r70 to %word
	%r73 = getelementptr [0 x %ptr], [0 x %ptr]* %r75, %word 0, %word %r74
	store %ptr %r69, %ptr* %r73
	%r72 = bitcast %ptr %r69 to %ptr
	store %ptr %r72, %ptr* %t6
	br label %L59
L59:
	%r76 = load %ptr, %ptr* %t6
	%r77 = inttoptr %word 1 to %ptr
	store %ptr %r77, %ptr* %t5
	%r78 = inttoptr %word 2 to %ptr
	%r79 = load %ptr, %ptr* %t1
	%r83 = bitcast %ptr %r79 to [0 x %ptr]*
	%r82 = ptrtoint %ptr %r78 to %word
	%r81 = getelementptr [0 x %ptr], [0 x %ptr]* %r83, %word 0, %word %r82
	%r80 = load %ptr, %ptr* %r81
	store %ptr %r80, %ptr* %t1
	%r84 = load %ptr, %ptr* @"gc/memory-base"
	%r88 = ptrtoint %ptr %r84 to %word
	%r87 = ptrtoint %ptr %r80 to %word
	%r86 = icmp eq %word %r88, %r87
	%r85 = inttoptr i1 %r86 to %ptr
	store %ptr %r85, %ptr* %t5
	%r89 = inttoptr %word 0 to %ptr
	%r93 = ptrtoint %ptr %r89 to %word
	%r92 = ptrtoint %ptr %r85 to %word
	%r91 = icmp eq %word %r93, %r92
	%r90 = inttoptr i1 %r91 to %ptr
	%r95 = ptrtoint %ptr %r90 to %word
	%r94 = icmp ne %word %r95, 0
	br i1 %r94, label %L60, label %L61
L61:
	%r96 = inttoptr %word 0 to %ptr
	store %ptr %r96, %ptr* %t1
	store %ptr %r96, %ptr* %t5
	%r97 = inttoptr %word 0 to %ptr
	%r101 = ptrtoint %ptr %r97 to %word
	%r100 = ptrtoint %ptr %r96 to %word
	%r99 = icmp eq %word %r101, %r100
	%r98 = inttoptr i1 %r99 to %ptr
	%r103 = ptrtoint %ptr %r98 to %word
	%r102 = icmp ne %word %r103, 0
	br i1 %r102, label %L60, label %L62
L62:
	br label %L60
L60:
	%r104 = load %ptr, %ptr* %t5
	br label %L55
L55:
	%r105 = load %ptr, %ptr* %t1
	%r107 = ptrtoint %ptr %r105 to %word
	%r106 = icmp ne %word %r107, 0
	br i1 %r106, label %L54, label %L56
L56:
	%r108 = load %ptr, %ptr* %t2
	store %ptr %r108, %ptr* @"gc/objects-live"
	%r109 = load %ptr, %ptr* %t3
	store %ptr %r109, %ptr* @"gc/bytes-used"
	%r110 = load %ptr, %ptr* %t4
	store %ptr %r110, %ptr* @"gc/bytes-free"
	%r111 = inttoptr %word 0 to %ptr
	ret %ptr %r111
}
define %ptr @"gc/mark-and-trace"(%ptr %obj) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	store %ptr %r2, %ptr* %t2
	%r3 = inttoptr %word 0 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	%r9 = ptrtoint %ptr %r4 to %word
	%r8 = icmp ne %word %r9, 0
	br i1 %r8, label %L63, label %L64
L64:
	%r10 = inttoptr %word 3 to %ptr
	%r11 = load %ptr, %ptr* %t1
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = and %word %r15, %r14
	%r12 = inttoptr %word %r13 to %ptr
	%r16 = inttoptr %word 0 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r12 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r24, 0
	%r22 = zext i1 %r23 to %word
	%r21 = inttoptr %word %r22 to %ptr
	%r28 = ptrtoint %ptr %r21 to %word
	%r27 = icmp eq %word %r28, 0
	%r26 = zext i1 %r27 to %word
	%r25 = inttoptr %word %r26 to %ptr
	store %ptr %r25, %ptr* %t2
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r25 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	%r35 = ptrtoint %ptr %r30 to %word
	%r34 = icmp ne %word %r35, 0
	br i1 %r34, label %L63, label %L65
L65:
	%r36 = inttoptr %word 16 to %ptr
	%r37 = load %ptr, %ptr* %t1
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = sub %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	store %ptr %r38, %ptr* %t3
	%r42 = inttoptr %word 1 to %ptr
	%r43 = load %ptr, %ptr* %t3
	%r47 = bitcast %ptr %r43 to [0 x %ptr]*
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = getelementptr [0 x %ptr], [0 x %ptr]* %r47, %word 0, %word %r46
	%r44 = load %ptr, %ptr* %r45
	store %ptr %r44, %ptr* %t4
	%r48 = inttoptr %word 0 to %ptr
	%r49 = inttoptr %word 0 to %ptr
	%r50 = inttoptr %word 0 to %ptr
	%r51 = inttoptr %word 0 to %ptr
	store %ptr %r51, %ptr* %t5
	%r52 = inttoptr %word 4 to %ptr
	%r53 = load %ptr, %ptr* %t4
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = and %word %r57, %r56
	%r54 = inttoptr %word %r55 to %ptr
	store %ptr %r54, %ptr* %t5
	%r58 = inttoptr %word 0 to %ptr
	%r62 = ptrtoint %ptr %r58 to %word
	%r61 = ptrtoint %ptr %r54 to %word
	%r60 = icmp eq %word %r62, %r61
	%r59 = inttoptr i1 %r60 to %ptr
	%r64 = ptrtoint %ptr %r59 to %word
	%r63 = icmp ne %word %r64, 0
	br i1 %r63, label %L67, label %L66
L67:
	%r65 = inttoptr %word 4 to %ptr
	%r66 = load %ptr, %ptr* %t4
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = or %word %r70, %r69
	%r67 = inttoptr %word %r68 to %ptr
	%r71 = inttoptr %word 1 to %ptr
	%r72 = load %ptr, %ptr* %t3
	%r76 = bitcast %ptr %r72 to [0 x %ptr]*
	%r75 = ptrtoint %ptr %r71 to %word
	%r74 = getelementptr [0 x %ptr], [0 x %ptr]* %r76, %word 0, %word %r75
	store %ptr %r67, %ptr* %r74
	%r73 = bitcast %ptr %r67 to %ptr
	%r77 = inttoptr %word 0 to %ptr
	store %ptr %r77, %ptr* %t6
	%r78 = inttoptr %word 2 to %ptr
	%r79 = load %ptr, %ptr* %t4
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = ptrtoint %ptr %r78 to %word
	%r81 = and %word %r83, %r82
	%r80 = inttoptr %word %r81 to %ptr
	store %ptr %r80, %ptr* %t6
	%r84 = inttoptr %word 0 to %ptr
	%r88 = ptrtoint %ptr %r84 to %word
	%r87 = ptrtoint %ptr %r80 to %word
	%r86 = icmp eq %word %r88, %r87
	%r85 = inttoptr i1 %r86 to %ptr
	%r90 = ptrtoint %ptr %r85 to %word
	%r89 = icmp ne %word %r90, 0
	br i1 %r89, label %L69, label %L68
L69:
	%r91 = inttoptr %word 4 to %ptr
	%r92 = inttoptr %word 0 to %ptr
	%r93 = load %ptr, %ptr* %t3
	%r97 = bitcast %ptr %r93 to [0 x %ptr]*
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = getelementptr [0 x %ptr], [0 x %ptr]* %r97, %word 0, %word %r96
	%r94 = load %ptr, %ptr* %r95
	%r101 = ptrtoint %ptr %r94 to %word
	%r100 = ptrtoint %ptr %r91 to %word
	%r99 = sdiv %word %r101, %r100
	%r98 = inttoptr %word %r99 to %ptr
	store %ptr %r98, %ptr* %t7
	%r102 = inttoptr %word 0 to %ptr
	%r103 = inttoptr %word 0 to %ptr
	br label %L71
L70:
	%r104 = inttoptr %word 1 to %ptr
	%r105 = load %ptr, %ptr* %t7
	%r109 = ptrtoint %ptr %r105 to %word
	%r108 = ptrtoint %ptr %r104 to %word
	%r107 = sub %word %r109, %r108
	%r106 = inttoptr %word %r107 to %ptr
	store %ptr %r106, %ptr* %t7
	%r110 = load %ptr, %ptr* %t7
	%r111 = load %ptr, %ptr* %t1
	%r115 = bitcast %ptr %r111 to [0 x %ptr]*
	%r114 = ptrtoint %ptr %r110 to %word
	%r113 = getelementptr [0 x %ptr], [0 x %ptr]* %r115, %word 0, %word %r114
	%r112 = load %ptr, %ptr* %r113
	%r116 = call %ptr @"gc/mark-and-trace"(%ptr %r112)
	br label %L71
L71:
	%r117 = load %ptr, %ptr* %t7
	%r119 = ptrtoint %ptr %r117 to %word
	%r118 = icmp ne %word %r119, 0
	br i1 %r118, label %L70, label %L72
L72:
	store %ptr %r117, %ptr* %t6
	%r120 = inttoptr %word 0 to %ptr
	%r124 = ptrtoint %ptr %r120 to %word
	%r123 = ptrtoint %ptr %r117 to %word
	%r122 = icmp eq %word %r124, %r123
	%r121 = inttoptr i1 %r122 to %ptr
	%r126 = ptrtoint %ptr %r121 to %word
	%r125 = icmp ne %word %r126, 0
	br i1 %r125, label %L73, label %L68
L73:
	br label %L68
L68:
	%r127 = load %ptr, %ptr* %t6
	store %ptr %r127, %ptr* %t5
	%r128 = inttoptr %word 0 to %ptr
	%r132 = ptrtoint %ptr %r128 to %word
	%r131 = ptrtoint %ptr %r127 to %word
	%r130 = icmp eq %word %r132, %r131
	%r129 = inttoptr i1 %r130 to %ptr
	%r134 = ptrtoint %ptr %r129 to %word
	%r133 = icmp ne %word %r134, 0
	br i1 %r133, label %L74, label %L66
L74:
	br label %L66
L66:
	%r135 = load %ptr, %ptr* %t5
	store %ptr %r135, %ptr* %t2
	%r136 = inttoptr %word 0 to %ptr
	%r140 = ptrtoint %ptr %r136 to %word
	%r139 = ptrtoint %ptr %r135 to %word
	%r138 = icmp eq %word %r140, %r139
	%r137 = inttoptr i1 %r138 to %ptr
	%r142 = ptrtoint %ptr %r137 to %word
	%r141 = icmp ne %word %r142, 0
	br i1 %r141, label %L63, label %L75
L75:
	br label %L63
L63:
	%r143 = load %ptr, %ptr* %t2
	ret %ptr %r143
}
define %ptr @"gc/collect"() {
	%t1 = alloca %ptr
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	store %ptr %r2, %ptr* %t1
	br label %L77
L76:
	%r3 = inttoptr %word 0 to %ptr
	%r4 = load %ptr, %ptr* %t1
	%r5 = load %ptr, %ptr* @"gc/roots"
	%r9 = bitcast %ptr %r5 to [0 x %ptr]*
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = getelementptr [0 x %ptr], [0 x %ptr]* %r9, %word 0, %word %r8
	%r6 = load %ptr, %ptr* %r7
	%r13 = bitcast %ptr %r6 to [0 x %ptr]*
	%r12 = ptrtoint %ptr %r3 to %word
	%r11 = getelementptr [0 x %ptr], [0 x %ptr]* %r13, %word 0, %word %r12
	%r10 = load %ptr, %ptr* %r11
	%r14 = call %ptr @"gc/mark-and-trace"(%ptr %r10)
	%r15 = load %ptr, %ptr* %t1
	%r16 = inttoptr %word 1 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = add %word %r20, %r19
	%r17 = inttoptr %word %r18 to %ptr
	store %ptr %r17, %ptr* %t1
	br label %L77
L77:
	%r21 = load %ptr, %ptr* @"gc/root-count"
	%r22 = load %ptr, %ptr* %t1
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = icmp slt %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L76, label %L78
L78:
	%r29 = call %ptr @"gc/sweep"()
	%r30 = inttoptr %word 0 to %ptr
	store %ptr %r30, %ptr* @"gc/alloc-count"
	ret %ptr %r30
}
define %ptr @"gc/allocate"(%ptr %requested-size) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	store %ptr %requested-size, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word -4 to %ptr
	%r3 = inttoptr %word 3 to %ptr
	%r4 = load %ptr, %ptr* %t1
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = add %word %r8, %r7
	%r5 = inttoptr %word %r6 to %ptr
	%r12 = ptrtoint %ptr %r5 to %word
	%r11 = ptrtoint %ptr %r2 to %word
	%r10 = and %word %r12, %r11
	%r9 = inttoptr %word %r10 to %ptr
	store %ptr %r9, %ptr* %t1
	%r13 = inttoptr %word 1 to %ptr
	store %ptr %r13, %ptr* %t2
	%r14 = load %ptr, %ptr* @"gc/frequency"
	%r15 = load %ptr, %ptr* @"gc/alloc-count"
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = icmp eq %word %r19, %r18
	%r16 = inttoptr i1 %r17 to %ptr
	store %ptr %r16, %ptr* %t2
	%r20 = inttoptr %word 0 to %ptr
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ptrtoint %ptr %r16 to %word
	%r22 = icmp eq %word %r24, %r23
	%r21 = inttoptr i1 %r22 to %ptr
	%r26 = ptrtoint %ptr %r21 to %word
	%r25 = icmp ne %word %r26, 0
	br i1 %r25, label %L79, label %L80
L80:
	%r27 = call %ptr @"gc/collect"()
	store %ptr %r27, %ptr* %t2
	%r28 = inttoptr %word 0 to %ptr
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = icmp eq %word %r32, %r31
	%r29 = inttoptr i1 %r30 to %ptr
	%r34 = ptrtoint %ptr %r29 to %word
	%r33 = icmp ne %word %r34, 0
	br i1 %r33, label %L79, label %L81
L81:
	br label %L79
L79:
	%r35 = load %ptr, %ptr* %t2
	%r36 = inttoptr %word 2 to %ptr
	%r37 = load %ptr, %ptr* @"gc/memory-last"
	%r41 = bitcast %ptr %r37 to [0 x %ptr]*
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = getelementptr [0 x %ptr], [0 x %ptr]* %r41, %word 0, %word %r40
	%r38 = load %ptr, %ptr* %r39
	store %ptr %r38, %ptr* %t2
	%r42 = load %ptr, %ptr* %t2
	store %ptr %r42, %ptr* %t3
	%r43 = inttoptr %word 16 to %ptr
	%r44 = load %ptr, %ptr* %t1
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = add %word %r48, %r47
	%r45 = inttoptr %word %r46 to %ptr
	store %ptr %r45, %ptr* %t4
	br label %L83
L82:
	br label %L86
L85:
	br label %L86
L86:
	%r49 = inttoptr %word 0 to %ptr
	%r50 = inttoptr %word 1 to %ptr
	store %ptr %r50, %ptr* %t5
	%r51 = inttoptr %word 1 to %ptr
	%r52 = load %ptr, %ptr* %t3
	%r56 = bitcast %ptr %r52 to [0 x %ptr]*
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = getelementptr [0 x %ptr], [0 x %ptr]* %r56, %word 0, %word %r55
	%r53 = load %ptr, %ptr* %r54
	%r57 = inttoptr %word 0 to %ptr
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r53 to %word
	%r59 = icmp eq %word %r61, %r60
	%r58 = inttoptr i1 %r59 to %ptr
	store %ptr %r58, %ptr* %t5
	%r62 = inttoptr %word 0 to %ptr
	%r66 = ptrtoint %ptr %r62 to %word
	%r65 = ptrtoint %ptr %r58 to %word
	%r64 = icmp eq %word %r66, %r65
	%r63 = inttoptr i1 %r64 to %ptr
	%r68 = ptrtoint %ptr %r63 to %word
	%r67 = icmp ne %word %r68, 0
	br i1 %r67, label %L88, label %L89
L89:
	%r69 = inttoptr %word 0 to %ptr
	%r70 = load %ptr, %ptr* %t3
	%r74 = bitcast %ptr %r70 to [0 x %ptr]*
	%r73 = ptrtoint %ptr %r69 to %word
	%r72 = getelementptr [0 x %ptr], [0 x %ptr]* %r74, %word 0, %word %r73
	%r71 = load %ptr, %ptr* %r72
	store %ptr %r71, %ptr* %t6
	br label %L91
L90:
	%r75 = inttoptr %word 2 to %ptr
	%r76 = load %ptr, %ptr* %t3
	%r80 = bitcast %ptr %r76 to [0 x %ptr]*
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = getelementptr [0 x %ptr], [0 x %ptr]* %r80, %word 0, %word %r79
	%r77 = load %ptr, %ptr* %r78
	store %ptr %r77, %ptr* %t7
	%r81 = inttoptr %word 2 to %ptr
	%r82 = load %ptr, %ptr* %t7
	%r86 = bitcast %ptr %r82 to [0 x %ptr]*
	%r85 = ptrtoint %ptr %r81 to %word
	%r84 = getelementptr [0 x %ptr], [0 x %ptr]* %r86, %word 0, %word %r85
	%r83 = load %ptr, %ptr* %r84
	%r87 = inttoptr %word 2 to %ptr
	%r88 = load %ptr, %ptr* %t3
	%r92 = bitcast %ptr %r88 to [0 x %ptr]*
	%r91 = ptrtoint %ptr %r87 to %word
	%r90 = getelementptr [0 x %ptr], [0 x %ptr]* %r92, %word 0, %word %r91
	store %ptr %r83, %ptr* %r90
	%r89 = bitcast %ptr %r83 to %ptr
	%r93 = inttoptr %word 0 to %ptr
	%r94 = load %ptr, %ptr* %t7
	%r98 = bitcast %ptr %r94 to [0 x %ptr]*
	%r97 = ptrtoint %ptr %r93 to %word
	%r96 = getelementptr [0 x %ptr], [0 x %ptr]* %r98, %word 0, %word %r97
	%r95 = load %ptr, %ptr* %r96
	%r99 = inttoptr %word 16 to %ptr
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = ptrtoint %ptr %r95 to %word
	%r101 = add %word %r103, %r102
	%r100 = inttoptr %word %r101 to %ptr
	%r104 = load %ptr, %ptr* %t6
	%r108 = ptrtoint %ptr %r104 to %word
	%r107 = ptrtoint %ptr %r100 to %word
	%r106 = add %word %r108, %r107
	%r105 = inttoptr %word %r106 to %ptr
	%r109 = inttoptr %word 0 to %ptr
	%r110 = load %ptr, %ptr* %t3
	%r114 = bitcast %ptr %r110 to [0 x %ptr]*
	%r113 = ptrtoint %ptr %r109 to %word
	%r112 = getelementptr [0 x %ptr], [0 x %ptr]* %r114, %word 0, %word %r113
	store %ptr %r105, %ptr* %r112
	%r111 = bitcast %ptr %r105 to %ptr
	store %ptr %r111, %ptr* %t6
	%r115 = inttoptr %word 1 to %ptr
	store %ptr %r115, %ptr* %t8
	%r116 = load %ptr, %ptr* @"gc/memory-last"
	%r117 = load %ptr, %ptr* %t7
	%r121 = ptrtoint %ptr %r117 to %word
	%r120 = ptrtoint %ptr %r116 to %word
	%r119 = icmp eq %word %r121, %r120
	%r118 = inttoptr i1 %r119 to %ptr
	store %ptr %r118, %ptr* %t8
	%r122 = inttoptr %word 0 to %ptr
	%r126 = ptrtoint %ptr %r122 to %word
	%r125 = ptrtoint %ptr %r118 to %word
	%r124 = icmp eq %word %r126, %r125
	%r123 = inttoptr i1 %r124 to %ptr
	%r128 = ptrtoint %ptr %r123 to %word
	%r127 = icmp ne %word %r128, 0
	br i1 %r127, label %L93, label %L94
L94:
	%r129 = load %ptr, %ptr* %t3
	store %ptr %r129, %ptr* @"gc/memory-last"
	store %ptr %r129, %ptr* %t8
	%r130 = inttoptr %word 0 to %ptr
	%r134 = ptrtoint %ptr %r130 to %word
	%r133 = ptrtoint %ptr %r129 to %word
	%r132 = icmp eq %word %r134, %r133
	%r131 = inttoptr i1 %r132 to %ptr
	%r136 = ptrtoint %ptr %r131 to %word
	%r135 = icmp ne %word %r136, 0
	br i1 %r135, label %L93, label %L95
L95:
	br label %L93
L93:
	%r137 = load %ptr, %ptr* %t8
	br label %L91
L91:
	%r138 = inttoptr %word 1 to %ptr
	store %ptr %r138, %ptr* %t7
	%r139 = inttoptr %word 1 to %ptr
	%r140 = inttoptr %word 2 to %ptr
	%r141 = load %ptr, %ptr* %t3
	%r145 = bitcast %ptr %r141 to [0 x %ptr]*
	%r144 = ptrtoint %ptr %r140 to %word
	%r143 = getelementptr [0 x %ptr], [0 x %ptr]* %r145, %word 0, %word %r144
	%r142 = load %ptr, %ptr* %r143
	%r149 = bitcast %ptr %r142 to [0 x %ptr]*
	%r148 = ptrtoint %ptr %r139 to %word
	%r147 = getelementptr [0 x %ptr], [0 x %ptr]* %r149, %word 0, %word %r148
	%r146 = load %ptr, %ptr* %r147
	%r150 = inttoptr %word 0 to %ptr
	%r154 = ptrtoint %ptr %r150 to %word
	%r153 = ptrtoint %ptr %r146 to %word
	%r152 = icmp eq %word %r154, %r153
	%r151 = inttoptr i1 %r152 to %ptr
	store %ptr %r151, %ptr* %t7
	%r155 = inttoptr %word 0 to %ptr
	%r159 = ptrtoint %ptr %r155 to %word
	%r158 = ptrtoint %ptr %r151 to %word
	%r157 = icmp eq %word %r159, %r158
	%r156 = inttoptr i1 %r157 to %ptr
	%r161 = ptrtoint %ptr %r156 to %word
	%r160 = icmp ne %word %r161, 0
	br i1 %r160, label %L96, label %L97
L97:
	%r162 = load %ptr, %ptr* %t6
	%r163 = inttoptr %word 16 to %ptr
	%r167 = ptrtoint %ptr %r163 to %word
	%r166 = ptrtoint %ptr %r162 to %word
	%r165 = add %word %r167, %r166
	%r164 = inttoptr %word %r165 to %ptr
	%r168 = load %ptr, %ptr* %t3
	%r172 = ptrtoint %ptr %r168 to %word
	%r171 = ptrtoint %ptr %r164 to %word
	%r170 = add %word %r172, %r171
	%r169 = inttoptr %word %r170 to %ptr
	%r173 = inttoptr %word 2 to %ptr
	%r174 = load %ptr, %ptr* %t3
	%r178 = bitcast %ptr %r174 to [0 x %ptr]*
	%r177 = ptrtoint %ptr %r173 to %word
	%r176 = getelementptr [0 x %ptr], [0 x %ptr]* %r178, %word 0, %word %r177
	%r175 = load %ptr, %ptr* %r176
	%r182 = ptrtoint %ptr %r175 to %word
	%r181 = ptrtoint %ptr %r169 to %word
	%r180 = icmp eq %word %r182, %r181
	%r179 = inttoptr i1 %r180 to %ptr
	store %ptr %r179, %ptr* %t7
	%r183 = inttoptr %word 0 to %ptr
	%r187 = ptrtoint %ptr %r183 to %word
	%r186 = ptrtoint %ptr %r179 to %word
	%r185 = icmp eq %word %r187, %r186
	%r184 = inttoptr i1 %r185 to %ptr
	%r189 = ptrtoint %ptr %r184 to %word
	%r188 = icmp ne %word %r189, 0
	br i1 %r188, label %L96, label %L98
L98:
	br label %L96
L96:
	%r190 = load %ptr, %ptr* %t7
	%r192 = ptrtoint %ptr %r190 to %word
	%r191 = icmp ne %word %r192, 0
	br i1 %r191, label %L90, label %L92
L92:
	%r193 = inttoptr %word 1 to %ptr
	store %ptr %r193, %ptr* %t7
	%r194 = inttoptr %word 0 to %ptr
	store %ptr %r194, %ptr* %t8
	%r195 = load %ptr, %ptr* %t6
	%r196 = load %ptr, %ptr* %t4
	%r200 = ptrtoint %ptr %r196 to %word
	%r199 = ptrtoint %ptr %r195 to %word
	%r198 = icmp slt %word %r200, %r199
	%r197 = inttoptr i1 %r198 to %ptr
	store %ptr %r197, %ptr* %t8
	%r201 = inttoptr %word 0 to %ptr
	%r205 = ptrtoint %ptr %r201 to %word
	%r204 = ptrtoint %ptr %r197 to %word
	%r203 = icmp eq %word %r205, %r204
	%r202 = inttoptr i1 %r203 to %ptr
	%r207 = ptrtoint %ptr %r202 to %word
	%r206 = icmp ne %word %r207, 0
	br i1 %r206, label %L101, label %L100
L101:
	%r208 = load %ptr, %ptr* %t6
	%r209 = load %ptr, %ptr* %t1
	%r213 = ptrtoint %ptr %r209 to %word
	%r212 = ptrtoint %ptr %r208 to %word
	%r211 = icmp eq %word %r213, %r212
	%r210 = inttoptr i1 %r211 to %ptr
	store %ptr %r210, %ptr* %t8
	%r214 = inttoptr %word 0 to %ptr
	%r218 = ptrtoint %ptr %r214 to %word
	%r217 = ptrtoint %ptr %r210 to %word
	%r216 = icmp eq %word %r218, %r217
	%r215 = inttoptr i1 %r216 to %ptr
	%r220 = ptrtoint %ptr %r215 to %word
	%r219 = icmp ne %word %r220, 0
	br i1 %r219, label %L102, label %L100
L102:
	br label %L100
L100:
	%r221 = load %ptr, %ptr* %t8
	store %ptr %r221, %ptr* %t7
	%r222 = inttoptr %word 0 to %ptr
	%r226 = ptrtoint %ptr %r222 to %word
	%r225 = ptrtoint %ptr %r221 to %word
	%r224 = icmp eq %word %r226, %r225
	%r223 = inttoptr i1 %r224 to %ptr
	%r228 = ptrtoint %ptr %r223 to %word
	%r227 = icmp ne %word %r228, 0
	br i1 %r227, label %L99, label %L103
L103:
	%r229 = inttoptr %word 0 to %ptr
	%r230 = inttoptr %word 1 to %ptr
	store %ptr %r230, %ptr* %t8
	%r231 = load %ptr, %ptr* %t4
	%r232 = load %ptr, %ptr* %t6
	%r236 = ptrtoint %ptr %r232 to %word
	%r235 = ptrtoint %ptr %r231 to %word
	%r234 = icmp sgt %word %r236, %r235
	%r233 = inttoptr i1 %r234 to %ptr
	store %ptr %r233, %ptr* %t8
	%r237 = inttoptr %word 0 to %ptr
	%r241 = ptrtoint %ptr %r237 to %word
	%r240 = ptrtoint %ptr %r233 to %word
	%r239 = icmp eq %word %r241, %r240
	%r238 = inttoptr i1 %r239 to %ptr
	%r243 = ptrtoint %ptr %r238 to %word
	%r242 = icmp ne %word %r243, 0
	br i1 %r242, label %L104, label %L105
L105:
	%r244 = load %ptr, %ptr* %t4
	%r245 = load %ptr, %ptr* %t3
	%r249 = ptrtoint %ptr %r245 to %word
	%r248 = ptrtoint %ptr %r244 to %word
	%r247 = add %word %r249, %r248
	%r246 = inttoptr %word %r247 to %ptr
	store %ptr %r246, %ptr* %t9
	%r250 = inttoptr %word 0 to %ptr
	%r251 = load %ptr, %ptr* %t4
	%r252 = load %ptr, %ptr* %t6
	%r256 = ptrtoint %ptr %r252 to %word
	%r255 = ptrtoint %ptr %r251 to %word
	%r254 = sub %word %r256, %r255
	%r253 = inttoptr %word %r254 to %ptr
	%r257 = inttoptr %word 0 to %ptr
	%r258 = load %ptr, %ptr* %t9
	%r262 = bitcast %ptr %r258 to [0 x %ptr]*
	%r261 = ptrtoint %ptr %r257 to %word
	%r260 = getelementptr [0 x %ptr], [0 x %ptr]* %r262, %word 0, %word %r261
	store %ptr %r253, %ptr* %r260
	%r259 = bitcast %ptr %r253 to %ptr
	%r263 = inttoptr %word 0 to %ptr
	%r264 = inttoptr %word 1 to %ptr
	%r265 = load %ptr, %ptr* %t9
	%r269 = bitcast %ptr %r265 to [0 x %ptr]*
	%r268 = ptrtoint %ptr %r264 to %word
	%r267 = getelementptr [0 x %ptr], [0 x %ptr]* %r269, %word 0, %word %r268
	store %ptr %r263, %ptr* %r267
	%r266 = bitcast %ptr %r263 to %ptr
	%r270 = inttoptr %word 2 to %ptr
	%r271 = load %ptr, %ptr* %t3
	%r275 = bitcast %ptr %r271 to [0 x %ptr]*
	%r274 = ptrtoint %ptr %r270 to %word
	%r273 = getelementptr [0 x %ptr], [0 x %ptr]* %r275, %word 0, %word %r274
	%r272 = load %ptr, %ptr* %r273
	%r276 = inttoptr %word 2 to %ptr
	%r277 = load %ptr, %ptr* %t9
	%r281 = bitcast %ptr %r277 to [0 x %ptr]*
	%r280 = ptrtoint %ptr %r276 to %word
	%r279 = getelementptr [0 x %ptr], [0 x %ptr]* %r281, %word 0, %word %r280
	store %ptr %r272, %ptr* %r279
	%r278 = bitcast %ptr %r272 to %ptr
	%r282 = load %ptr, %ptr* %t1
	%r283 = inttoptr %word 0 to %ptr
	%r284 = load %ptr, %ptr* %t3
	%r288 = bitcast %ptr %r284 to [0 x %ptr]*
	%r287 = ptrtoint %ptr %r283 to %word
	%r286 = getelementptr [0 x %ptr], [0 x %ptr]* %r288, %word 0, %word %r287
	store %ptr %r282, %ptr* %r286
	%r285 = bitcast %ptr %r282 to %ptr
	%r289 = load %ptr, %ptr* %t9
	%r290 = inttoptr %word 2 to %ptr
	%r291 = load %ptr, %ptr* %t3
	%r295 = bitcast %ptr %r291 to [0 x %ptr]*
	%r294 = ptrtoint %ptr %r290 to %word
	%r293 = getelementptr [0 x %ptr], [0 x %ptr]* %r295, %word 0, %word %r294
	store %ptr %r289, %ptr* %r293
	%r292 = bitcast %ptr %r289 to %ptr
	%r296 = load %ptr, %ptr* %t1
	store %ptr %r296, %ptr* %t6
	store %ptr %r296, %ptr* %t8
	%r297 = inttoptr %word 0 to %ptr
	%r301 = ptrtoint %ptr %r297 to %word
	%r300 = ptrtoint %ptr %r296 to %word
	%r299 = icmp eq %word %r301, %r300
	%r298 = inttoptr i1 %r299 to %ptr
	%r303 = ptrtoint %ptr %r298 to %word
	%r302 = icmp ne %word %r303, 0
	br i1 %r302, label %L104, label %L106
L106:
	br label %L104
L104:
	%r304 = load %ptr, %ptr* %t8
	%r305 = inttoptr %word 1 to %ptr
	%r306 = inttoptr %word 1 to %ptr
	%r307 = load %ptr, %ptr* %t3
	%r311 = bitcast %ptr %r307 to [0 x %ptr]*
	%r310 = ptrtoint %ptr %r306 to %word
	%r309 = getelementptr [0 x %ptr], [0 x %ptr]* %r311, %word 0, %word %r310
	store %ptr %r305, %ptr* %r309
	%r308 = bitcast %ptr %r305 to %ptr
	%r312 = load %ptr, %ptr* %t3
	store %ptr %r312, %ptr* @"gc/memory-last"
	%r313 = inttoptr %word 0 to %ptr
	%r314 = inttoptr %word 16 to %ptr
	%r315 = load %ptr, %ptr* %t3
	%r319 = ptrtoint %ptr %r315 to %word
	%r318 = ptrtoint %ptr %r314 to %word
	%r317 = add %word %r319, %r318
	%r316 = inttoptr %word %r317 to %ptr
	store %ptr %r316, %ptr* %t8
	%r320 = load %ptr, %ptr* %t8
	%r321 = inttoptr %word 0 to %ptr
	%r322 = load %ptr, %ptr* %t6
	%ffi-cast323 = ptrtoint %ptr %r321 to i32
	%ffi-cast324 = ptrtoint %ptr %r322 to i32
	%r325 = call %ptr @memset(%ptr %r320, i32 %ffi-cast323, i32 %ffi-cast324)
	%r326 = inttoptr %word 1 to %ptr
	%r327 = load %ptr, %ptr* @"gc/alloc-count"
	%r331 = ptrtoint %ptr %r327 to %word
	%r330 = ptrtoint %ptr %r326 to %word
	%r329 = add %word %r331, %r330
	%r328 = inttoptr %word %r329 to %ptr
	store %ptr %r328, %ptr* @"gc/alloc-count"
	%r332 = inttoptr %word 0 to %ptr
	%r333 = inttoptr %word 0 to %ptr
	%r334 = inttoptr %word 0 to %ptr
	%r335 = inttoptr %word 0 to %ptr
	%r336 = load %ptr, %ptr* %t8
	ret %ptr %r336
	store %ptr %r336, %ptr* %t7
	%r338 = inttoptr %word 0 to %ptr
	%r342 = ptrtoint %ptr %r338 to %word
	%r341 = ptrtoint %ptr %r336 to %word
	%r340 = icmp eq %word %r342, %r341
	%r339 = inttoptr i1 %r340 to %ptr
	%r344 = ptrtoint %ptr %r339 to %word
	%r343 = icmp ne %word %r344, 0
	br i1 %r343, label %L99, label %L107
L107:
	br label %L99
L99:
	%r345 = load %ptr, %ptr* %t7
	store %ptr %r345, %ptr* %t5
	%r346 = inttoptr %word 0 to %ptr
	%r350 = ptrtoint %ptr %r346 to %word
	%r349 = ptrtoint %ptr %r345 to %word
	%r348 = icmp eq %word %r350, %r349
	%r347 = inttoptr i1 %r348 to %ptr
	%r352 = ptrtoint %ptr %r347 to %word
	%r351 = icmp ne %word %r352, 0
	br i1 %r351, label %L88, label %L108
L108:
	br label %L88
L88:
	%r353 = load %ptr, %ptr* %t5
	%r354 = inttoptr %word 2 to %ptr
	%r355 = load %ptr, %ptr* %t3
	%r359 = bitcast %ptr %r355 to [0 x %ptr]*
	%r358 = ptrtoint %ptr %r354 to %word
	%r357 = getelementptr [0 x %ptr], [0 x %ptr]* %r359, %word 0, %word %r358
	%r356 = load %ptr, %ptr* %r357
	store %ptr %r356, %ptr* %t3
	%r360 = load %ptr, %ptr* %t2
	%r364 = ptrtoint %ptr %r360 to %word
	%r363 = ptrtoint %ptr %r356 to %word
	%r362 = icmp ne %word %r364, %r363
	%r361 = inttoptr i1 %r362 to %ptr
	%r366 = ptrtoint %ptr %r361 to %word
	%r365 = icmp ne %word %r366, 0
	br i1 %r365, label %L85, label %L87
L87:
	%r367 = load %ptr, %ptr* %t1
	%r368 = inttoptr %word 16 to %ptr
	%r372 = ptrtoint %ptr %r368 to %word
	%r371 = ptrtoint %ptr %r367 to %word
	%r370 = add %word %r372, %r371
	%r369 = inttoptr %word %r370 to %ptr
	%r373 = load %ptr, %ptr* @"gc/quantum"
	%r374 = call %ptr @max(%ptr %r369, %ptr %r373)
	%r375 = call %ptr @"gc/grow-heap"(%ptr %r374)
	br label %L83
L83:
	%r376 = inttoptr %word 1 to %ptr
	%r378 = ptrtoint %ptr %r376 to %word
	%r377 = icmp ne %word %r378, 0
	br i1 %r377, label %L82, label %L84
L84:
	ret %ptr %r376
}
define %ptr @"gc/allocate-opaque"(%ptr %size) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %size, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"gc/allocate"(%ptr %r1)
	store %ptr %r2, %ptr* %t2
	%r3 = inttoptr %word 2 to %ptr
	%r4 = inttoptr %word 1 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = add %word %r8, %r7
	%r5 = inttoptr %word %r6 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = inttoptr %word 16 to %ptr
	%r11 = load %ptr, %ptr* %t2
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = sub %word %r15, %r14
	%r12 = inttoptr %word %r13 to %ptr
	%r19 = bitcast %ptr %r12 to [0 x %ptr]*
	%r18 = ptrtoint %ptr %r9 to %word
	%r17 = getelementptr [0 x %ptr], [0 x %ptr]* %r19, %word 0, %word %r18
	store %ptr %r5, %ptr* %r17
	%r16 = bitcast %ptr %r5 to %ptr
	%r20 = load %ptr, %ptr* %t2
	ret %ptr %r20
}
@str113 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str114 = private unnamed_addr constant [27 x i8] c"k/car called on non-list: \00"
@str115 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/car"(%ptr %list) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %list, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	store %ptr %r2, %ptr* %t2
	%r3 = inttoptr %word 0 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	%r9 = ptrtoint %ptr %r4 to %word
	%r8 = icmp ne %word %r9, 0
	br i1 %r8, label %L109, label %L110
L110:
	%r10 = inttoptr %word 0 to %ptr
	store %ptr %r10, %ptr* %t3
	%r11 = load %ptr, %ptr* %t1
	%r12 = call %ptr @"get/type"(%ptr %r11)
	%r13 = inttoptr %word 19 to %ptr
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = icmp eq %word %r17, %r16
	%r14 = inttoptr i1 %r15 to %ptr
	store %ptr %r14, %ptr* %t3
	%r18 = inttoptr %word 0 to %ptr
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = ptrtoint %ptr %r14 to %word
	%r20 = icmp eq %word %r22, %r21
	%r19 = inttoptr i1 %r20 to %ptr
	%r24 = ptrtoint %ptr %r19 to %word
	%r23 = icmp ne %word %r24, 0
	br i1 %r23, label %L112, label %L111
L112:
	%r25 = getelementptr [9 x i8], [9 x i8]* @str113, %word 0, %word 0
	%r27 = call i32 (%ptr, ...) @printf(%ptr %r25)
	%r28 = inttoptr %word %r27 to %ptr
	%r29 = getelementptr [27 x i8], [27 x i8]* @str114, %word 0, %word 0
	%r31 = call i32 (%ptr, ...) @printf(%ptr %r29)
	%r32 = inttoptr %word %r31 to %ptr
	%r33 = load %ptr, %ptr* %t1
	%r34 = call %ptr @"k/print"(%ptr %r33)
	%r35 = getelementptr [2 x i8], [2 x i8]* @str115, %word 0, %word 0
	%r37 = call i32 (%ptr, ...) @printf(%ptr %r35)
	%r38 = inttoptr %word %r37 to %ptr
	%r39 = call %ptr @die()
	store %ptr %r39, %ptr* %t3
	%r40 = inttoptr %word 0 to %ptr
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = icmp eq %word %r44, %r43
	%r41 = inttoptr i1 %r42 to %ptr
	%r46 = ptrtoint %ptr %r41 to %word
	%r45 = icmp ne %word %r46, 0
	br i1 %r45, label %L116, label %L111
L116:
	br label %L111
L111:
	%r47 = load %ptr, %ptr* %t3
	%r48 = inttoptr %word 0 to %ptr
	%r49 = load %ptr, %ptr* %t1
	%r53 = bitcast %ptr %r49 to [0 x %ptr]*
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = getelementptr [0 x %ptr], [0 x %ptr]* %r53, %word 0, %word %r52
	%r50 = load %ptr, %ptr* %r51
	store %ptr %r50, %ptr* %t2
	%r54 = inttoptr %word 0 to %ptr
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = ptrtoint %ptr %r50 to %word
	%r56 = icmp eq %word %r58, %r57
	%r55 = inttoptr i1 %r56 to %ptr
	%r60 = ptrtoint %ptr %r55 to %word
	%r59 = icmp ne %word %r60, 0
	br i1 %r59, label %L109, label %L117
L117:
	br label %L109
L109:
	%r61 = load %ptr, %ptr* %t2
	ret %ptr %r61
}
@str122 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str123 = private unnamed_addr constant [27 x i8] c"k/cdr called on non-list: \00"
@str124 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/cdr"(%ptr %list) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %list, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	store %ptr %r2, %ptr* %t2
	%r3 = inttoptr %word 0 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	%r9 = ptrtoint %ptr %r4 to %word
	%r8 = icmp ne %word %r9, 0
	br i1 %r8, label %L118, label %L119
L119:
	%r10 = inttoptr %word 0 to %ptr
	store %ptr %r10, %ptr* %t3
	%r11 = load %ptr, %ptr* %t1
	%r12 = call %ptr @"get/type"(%ptr %r11)
	%r13 = inttoptr %word 19 to %ptr
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = icmp eq %word %r17, %r16
	%r14 = inttoptr i1 %r15 to %ptr
	store %ptr %r14, %ptr* %t3
	%r18 = inttoptr %word 0 to %ptr
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = ptrtoint %ptr %r14 to %word
	%r20 = icmp eq %word %r22, %r21
	%r19 = inttoptr i1 %r20 to %ptr
	%r24 = ptrtoint %ptr %r19 to %word
	%r23 = icmp ne %word %r24, 0
	br i1 %r23, label %L121, label %L120
L121:
	%r25 = getelementptr [9 x i8], [9 x i8]* @str122, %word 0, %word 0
	%r27 = call i32 (%ptr, ...) @printf(%ptr %r25)
	%r28 = inttoptr %word %r27 to %ptr
	%r29 = getelementptr [27 x i8], [27 x i8]* @str123, %word 0, %word 0
	%r31 = call i32 (%ptr, ...) @printf(%ptr %r29)
	%r32 = inttoptr %word %r31 to %ptr
	%r33 = load %ptr, %ptr* %t1
	%r34 = call %ptr @"k/print"(%ptr %r33)
	%r35 = getelementptr [2 x i8], [2 x i8]* @str124, %word 0, %word 0
	%r37 = call i32 (%ptr, ...) @printf(%ptr %r35)
	%r38 = inttoptr %word %r37 to %ptr
	%r39 = call %ptr @die()
	store %ptr %r39, %ptr* %t3
	%r40 = inttoptr %word 0 to %ptr
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = icmp eq %word %r44, %r43
	%r41 = inttoptr i1 %r42 to %ptr
	%r46 = ptrtoint %ptr %r41 to %word
	%r45 = icmp ne %word %r46, 0
	br i1 %r45, label %L125, label %L120
L125:
	br label %L120
L120:
	%r47 = load %ptr, %ptr* %t3
	%r48 = inttoptr %word 1 to %ptr
	%r49 = load %ptr, %ptr* %t1
	%r53 = bitcast %ptr %r49 to [0 x %ptr]*
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = getelementptr [0 x %ptr], [0 x %ptr]* %r53, %word 0, %word %r52
	%r50 = load %ptr, %ptr* %r51
	store %ptr %r50, %ptr* %t2
	%r54 = inttoptr %word 0 to %ptr
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = ptrtoint %ptr %r50 to %word
	%r56 = icmp eq %word %r58, %r57
	%r55 = inttoptr i1 %r56 to %ptr
	%r60 = ptrtoint %ptr %r55 to %word
	%r59 = icmp ne %word %r60, 0
	br i1 %r59, label %L118, label %L126
L126:
	br label %L118
L118:
	%r61 = load %ptr, %ptr* %t2
	ret %ptr %r61
}
define %ptr @"k/caar"(%ptr %list) {
	%t1 = alloca %ptr
	store %ptr %list, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	%r3 = call %ptr @"k/car"(%ptr %r2)
	ret %ptr %r3
}
define %ptr @"k/cadr"(%ptr %list) {
	%t1 = alloca %ptr
	store %ptr %list, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/cdr"(%ptr %r1)
	%r3 = call %ptr @"k/car"(%ptr %r2)
	ret %ptr %r3
}
define %ptr @"k/cddr"(%ptr %list) {
	%t1 = alloca %ptr
	store %ptr %list, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/cdr"(%ptr %r1)
	%r3 = call %ptr @"k/cdr"(%ptr %r2)
	ret %ptr %r3
}
define %ptr @"k/caddr"(%ptr %list) {
	%t1 = alloca %ptr
	store %ptr %list, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/cdr"(%ptr %r1)
	%r3 = call %ptr @"k/cdr"(%ptr %r2)
	%r4 = call %ptr @"k/car"(%ptr %r3)
	ret %ptr %r4
}
define %ptr @"k/cadddr"(%ptr %list) {
	%t1 = alloca %ptr
	store %ptr %list, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/cdr"(%ptr %r1)
	%r3 = call %ptr @"k/cdr"(%ptr %r2)
	%r4 = call %ptr @"k/cdr"(%ptr %r3)
	%r5 = call %ptr @"k/car"(%ptr %r4)
	ret %ptr %r5
}
@str129 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str130 = private unnamed_addr constant [59 x i8] c"new-object: gc/allocate returned not aligned-to-oop? {%p}\0A\00"
@str131 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"%new-object"(%ptr %type, %ptr %bytesize) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %type, %ptr* %t1
	store %ptr %bytesize, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t2
	%r4 = call %ptr @"gc/allocate"(%ptr %r3)
	store %ptr %r4, %ptr* %t3
	%r5 = inttoptr %word 16 to %ptr
	%r6 = load %ptr, %ptr* %t3
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = sub %word %r10, %r9
	%r7 = inttoptr %word %r8 to %ptr
	store %ptr %r7, %ptr* %t4
	%r11 = inttoptr %word 0 to %ptr
	store %ptr %r11, %ptr* %t5
	%r12 = inttoptr %word 3 to %ptr
	%r13 = load %ptr, %ptr* %t3
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = and %word %r17, %r16
	%r14 = inttoptr %word %r15 to %ptr
	%r18 = inttoptr %word 0 to %ptr
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = ptrtoint %ptr %r14 to %word
	%r20 = icmp eq %word %r22, %r21
	%r19 = inttoptr i1 %r20 to %ptr
	store %ptr %r19, %ptr* %t5
	%r23 = inttoptr %word 0 to %ptr
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r19 to %word
	%r25 = icmp eq %word %r27, %r26
	%r24 = inttoptr i1 %r25 to %ptr
	%r29 = ptrtoint %ptr %r24 to %word
	%r28 = icmp ne %word %r29, 0
	br i1 %r28, label %L128, label %L127
L128:
	%r30 = getelementptr [9 x i8], [9 x i8]* @str129, %word 0, %word 0
	%r32 = call i32 (%ptr, ...) @printf(%ptr %r30)
	%r33 = inttoptr %word %r32 to %ptr
	%r34 = getelementptr [59 x i8], [59 x i8]* @str130, %word 0, %word 0
	%r36 = call i32 (%ptr, ...) @printf(%ptr %r34)
	%r37 = inttoptr %word %r36 to %ptr
	%r38 = load %ptr, %ptr* %t3
	%r39 = call %ptr @"k/print"(%ptr %r38)
	%r40 = getelementptr [2 x i8], [2 x i8]* @str131, %word 0, %word 0
	%r42 = call i32 (%ptr, ...) @printf(%ptr %r40)
	%r43 = inttoptr %word %r42 to %ptr
	%r44 = call %ptr @die()
	store %ptr %r44, %ptr* %t5
	%r45 = inttoptr %word 0 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = icmp eq %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	%r51 = ptrtoint %ptr %r46 to %word
	%r50 = icmp ne %word %r51, 0
	br i1 %r50, label %L132, label %L127
L132:
	br label %L127
L127:
	%r52 = load %ptr, %ptr* %t5
	%r53 = load %ptr, %ptr* %t1
	%r54 = inttoptr %word 3 to %ptr
	%r55 = load %ptr, %ptr* %t4
	%r59 = bitcast %ptr %r55 to [0 x %ptr]*
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = getelementptr [0 x %ptr], [0 x %ptr]* %r59, %word 0, %word %r58
	store %ptr %r53, %ptr* %r57
	%r56 = bitcast %ptr %r53 to %ptr
	%r60 = inttoptr %word 0 to %ptr
	%r61 = load %ptr, %ptr* %t3
	ret %ptr %r61
}
define %ptr @"%new-object/opaque"(%ptr %type, %ptr %bytesize) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %type, %ptr* %t1
	store %ptr %bytesize, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t2
	%r3 = call %ptr @"gc/allocate-opaque"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 16 to %ptr
	%r5 = load %ptr, %ptr* %t3
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = sub %word %r9, %r8
	%r6 = inttoptr %word %r7 to %ptr
	store %ptr %r6, %ptr* %t4
	%r10 = load %ptr, %ptr* %t1
	%r11 = inttoptr %word 3 to %ptr
	%r12 = load %ptr, %ptr* %t4
	%r16 = bitcast %ptr %r12 to [0 x %ptr]*
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = getelementptr [0 x %ptr], [0 x %ptr]* %r16, %word 0, %word %r15
	store %ptr %r10, %ptr* %r14
	%r13 = bitcast %ptr %r10 to %ptr
	%r17 = load %ptr, %ptr* %t3
	ret %ptr %r17
}
define %ptr @"new-<target-vm-pointer>"(%ptr %bits) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %bits, %ptr* %t1
	%r1 = inttoptr %word 16 to %ptr
	%r2 = inttoptr %word 4 to %ptr
	%r3 = call %ptr @"%new-object/opaque"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t2
	%r4 = load %ptr, %ptr* %t1
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t2
	%r10 = bitcast %ptr %r6 to [0 x %ptr]*
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = getelementptr [0 x %ptr], [0 x %ptr]* %r10, %word 0, %word %r9
	store %ptr %r4, %ptr* %r8
	%r7 = bitcast %ptr %r4 to %ptr
	%r11 = load %ptr, %ptr* %t2
	ret %ptr %r11
}
define %ptr @"new-<pair>"(%ptr %head, %ptr %tail) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %head, %ptr* %t1
	store %ptr %tail, %ptr* %t2
	%r1 = inttoptr %word 19 to %ptr
	%r2 = inttoptr %word 8 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t1
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t3
	%r10 = bitcast %ptr %r6 to [0 x %ptr]*
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = getelementptr [0 x %ptr], [0 x %ptr]* %r10, %word 0, %word %r9
	store %ptr %r4, %ptr* %r8
	%r7 = bitcast %ptr %r4 to %ptr
	%r11 = load %ptr, %ptr* %t2
	%r12 = inttoptr %word 1 to %ptr
	%r13 = load %ptr, %ptr* %t3
	%r17 = bitcast %ptr %r13 to [0 x %ptr]*
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = getelementptr [0 x %ptr], [0 x %ptr]* %r17, %word 0, %word %r16
	store %ptr %r11, %ptr* %r15
	%r14 = bitcast %ptr %r11 to %ptr
	%r18 = load %ptr, %ptr* %t3
	ret %ptr %r18
}
define %ptr @"k/string-length"(%ptr %obj) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	%r2 = load %ptr, %ptr* %t1
	store %ptr %r2, %ptr* %t2
	%r3 = inttoptr %word 0 to %ptr
	%r4 = inttoptr %word 0 to %ptr
	%r5 = load %ptr, %ptr* %t2
	%r9 = bitcast %ptr %r5 to [0 x %ptr]*
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = getelementptr [0 x %ptr], [0 x %ptr]* %r9, %word 0, %word %r8
	%r6 = load %ptr, %ptr* %r7
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = ptrtoint %ptr %r1 to %word
	%r11 = ashr %word %r13, %r12
	%r10 = inttoptr %word %r11 to %ptr
	ret %ptr %r10
}
define %ptr @"k/array-length"(%ptr %obj) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	%r2 = load %ptr, %ptr* %t1
	store %ptr %r2, %ptr* %t2
	%r3 = inttoptr %word 0 to %ptr
	%r4 = inttoptr %word 0 to %ptr
	%r5 = load %ptr, %ptr* %t2
	%r9 = bitcast %ptr %r5 to [0 x %ptr]*
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = getelementptr [0 x %ptr], [0 x %ptr]* %r9, %word 0, %word %r8
	%r6 = load %ptr, %ptr* %r7
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = ptrtoint %ptr %r1 to %word
	%r11 = ashr %word %r13, %r12
	%r10 = inttoptr %word %r11 to %ptr
	ret %ptr %r10
}
define %ptr @"k/array-at"(%ptr %obj, %ptr %idx) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	store %ptr %idx, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"get/type"(%ptr %r3)
	%r5 = inttoptr %word 7 to %ptr
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	store %ptr %r6, %ptr* %t3
	%r10 = inttoptr %word 0 to %ptr
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = icmp eq %word %r14, %r13
	%r11 = inttoptr i1 %r12 to %ptr
	%r16 = ptrtoint %ptr %r11 to %word
	%r15 = icmp ne %word %r16, 0
	br i1 %r15, label %L133, label %L134
L134:
	%r17 = load %ptr, %ptr* %t1
	store %ptr %r17, %ptr* %t4
	%r18 = inttoptr %word 0 to %ptr
	%r19 = inttoptr %word 1 to %ptr
	%r20 = load %ptr, %ptr* %t4
	%r24 = bitcast %ptr %r20 to [0 x %ptr]*
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = getelementptr [0 x %ptr], [0 x %ptr]* %r24, %word 0, %word %r23
	%r21 = load %ptr, %ptr* %r22
	store %ptr %r21, %ptr* %t4
	%r25 = load %ptr, %ptr* %t1
	%r26 = call %ptr @"k/array-length"(%ptr %r25)
	store %ptr %r26, %ptr* %t5
	%r27 = inttoptr %word 1 to %ptr
	store %ptr %r27, %ptr* %t6
	%r28 = load %ptr, %ptr* %t2
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = icmp sle %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	store %ptr %r30, %ptr* %t6
	%r34 = inttoptr %word 0 to %ptr
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = icmp eq %word %r38, %r37
	%r35 = inttoptr i1 %r36 to %ptr
	%r40 = ptrtoint %ptr %r35 to %word
	%r39 = icmp ne %word %r40, 0
	br i1 %r39, label %L135, label %L136
L136:
	%r41 = load %ptr, %ptr* %t5
	%r42 = load %ptr, %ptr* %t2
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = icmp slt %word %r46, %r45
	%r43 = inttoptr i1 %r44 to %ptr
	store %ptr %r43, %ptr* %t6
	%r47 = inttoptr %word 0 to %ptr
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r43 to %word
	%r49 = icmp eq %word %r51, %r50
	%r48 = inttoptr i1 %r49 to %ptr
	%r53 = ptrtoint %ptr %r48 to %word
	%r52 = icmp ne %word %r53, 0
	br i1 %r52, label %L135, label %L137
L137:
	%r54 = load %ptr, %ptr* %t2
	%r55 = load %ptr, %ptr* %t4
	%r59 = bitcast %ptr %r55 to [0 x %ptr]*
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = getelementptr [0 x %ptr], [0 x %ptr]* %r59, %word 0, %word %r58
	%r56 = load %ptr, %ptr* %r57
	store %ptr %r56, %ptr* %t6
	%r60 = inttoptr %word 0 to %ptr
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r56 to %word
	%r62 = icmp eq %word %r64, %r63
	%r61 = inttoptr i1 %r62 to %ptr
	%r66 = ptrtoint %ptr %r61 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L135, label %L138
L138:
	br label %L135
L135:
	%r67 = load %ptr, %ptr* %t6
	store %ptr %r67, %ptr* %t3
	%r68 = inttoptr %word 0 to %ptr
	%r72 = ptrtoint %ptr %r68 to %word
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = icmp eq %word %r72, %r71
	%r69 = inttoptr i1 %r70 to %ptr
	%r74 = ptrtoint %ptr %r69 to %word
	%r73 = icmp ne %word %r74, 0
	br i1 %r73, label %L133, label %L139
L139:
	br label %L133
L133:
	%r75 = load %ptr, %ptr* %t3
	ret %ptr %r75
}
define %ptr @"k/set-array-at"(%ptr %obj, %ptr %idx, %ptr %val) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	store %ptr %idx, %ptr* %t2
	store %ptr %val, %ptr* %t3
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t4
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"get/type"(%ptr %r3)
	%r5 = inttoptr %word 7 to %ptr
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	store %ptr %r6, %ptr* %t4
	%r10 = inttoptr %word 0 to %ptr
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = icmp eq %word %r14, %r13
	%r11 = inttoptr i1 %r12 to %ptr
	%r16 = ptrtoint %ptr %r11 to %word
	%r15 = icmp ne %word %r16, 0
	br i1 %r15, label %L140, label %L141
L141:
	%r17 = load %ptr, %ptr* %t1
	store %ptr %r17, %ptr* %t5
	%r18 = inttoptr %word 0 to %ptr
	%r19 = inttoptr %word 1 to %ptr
	%r20 = load %ptr, %ptr* %t5
	%r24 = bitcast %ptr %r20 to [0 x %ptr]*
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = getelementptr [0 x %ptr], [0 x %ptr]* %r24, %word 0, %word %r23
	%r21 = load %ptr, %ptr* %r22
	store %ptr %r21, %ptr* %t5
	%r25 = load %ptr, %ptr* %t1
	%r26 = call %ptr @"k/array-length"(%ptr %r25)
	store %ptr %r26, %ptr* %t6
	%r27 = inttoptr %word 4 to %ptr
	%r28 = load %ptr, %ptr* %t5
	%r29 = call %ptr @"gc/object-size"(%ptr %r28)
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r27 to %word
	%r31 = sdiv %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	store %ptr %r30, %ptr* %t7
	%r34 = inttoptr %word 1 to %ptr
	store %ptr %r34, %ptr* %t8
	%r35 = load %ptr, %ptr* %t2
	%r36 = inttoptr %word 0 to %ptr
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = icmp sle %word %r40, %r39
	%r37 = inttoptr i1 %r38 to %ptr
	store %ptr %r37, %ptr* %t8
	%r41 = inttoptr %word 0 to %ptr
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = ptrtoint %ptr %r37 to %word
	%r43 = icmp eq %word %r45, %r44
	%r42 = inttoptr i1 %r43 to %ptr
	%r47 = ptrtoint %ptr %r42 to %word
	%r46 = icmp ne %word %r47, 0
	br i1 %r46, label %L142, label %L143
L143:
	%r48 = inttoptr %word 0 to %ptr
	store %ptr %r48, %ptr* %t9
	%r49 = load %ptr, %ptr* %t7
	%r50 = load %ptr, %ptr* %t2
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = ptrtoint %ptr %r49 to %word
	%r52 = icmp slt %word %r54, %r53
	%r51 = inttoptr i1 %r52 to %ptr
	store %ptr %r51, %ptr* %t9
	%r55 = inttoptr %word 0 to %ptr
	%r59 = ptrtoint %ptr %r55 to %word
	%r58 = ptrtoint %ptr %r51 to %word
	%r57 = icmp eq %word %r59, %r58
	%r56 = inttoptr i1 %r57 to %ptr
	%r61 = ptrtoint %ptr %r56 to %word
	%r60 = icmp ne %word %r61, 0
	br i1 %r60, label %L145, label %L144
L145:
	br label %L147
L146:
	%r62 = inttoptr %word 2 to %ptr
	%r63 = load %ptr, %ptr* %t7
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r62 to %word
	%r65 = mul %word %r67, %r66
	%r64 = inttoptr %word %r65 to %ptr
	store %ptr %r64, %ptr* %t7
	br label %L147
L147:
	%r68 = load %ptr, %ptr* %t7
	%r69 = load %ptr, %ptr* %t2
	%r73 = ptrtoint %ptr %r69 to %word
	%r72 = ptrtoint %ptr %r68 to %word
	%r71 = icmp slt %word %r73, %r72
	%r70 = inttoptr i1 %r71 to %ptr
	%r77 = ptrtoint %ptr %r70 to %word
	%r76 = icmp eq %word %r77, 0
	%r75 = zext i1 %r76 to %word
	%r74 = inttoptr %word %r75 to %ptr
	%r79 = ptrtoint %ptr %r74 to %word
	%r78 = icmp ne %word %r79, 0
	br i1 %r78, label %L146, label %L148
L148:
	%r80 = inttoptr %word 5 to %ptr
	%r81 = inttoptr %word 4 to %ptr
	%r82 = load %ptr, %ptr* %t7
	%r86 = ptrtoint %ptr %r82 to %word
	%r85 = ptrtoint %ptr %r81 to %word
	%r84 = mul %word %r86, %r85
	%r83 = inttoptr %word %r84 to %ptr
	%r87 = call %ptr @"%new-object"(%ptr %r80, %ptr %r83)
	store %ptr %r87, %ptr* %t10
	%r89 = getelementptr %ptr, %ptr* %t10, %word 0
	%r88 = bitcast %ptr* %r89 to %ptr
	%r90 = call %ptr @"gc/push-root"(%ptr %r88)
	%r91 = load %ptr, %ptr* %t10
	%r92 = load %ptr, %ptr* %t5
	%r93 = inttoptr %word 4 to %ptr
	%r94 = load %ptr, %ptr* %t6
	%r98 = ptrtoint %ptr %r94 to %word
	%r97 = ptrtoint %ptr %r93 to %word
	%r96 = mul %word %r98, %r97
	%r95 = inttoptr %word %r96 to %ptr
	%ffi-cast99 = ptrtoint %ptr %r95 to i32
	%r100 = call %ptr @memcpy(%ptr %r91, %ptr %r92, i32 %ffi-cast99)
	%r101 = load %ptr, %ptr* %t1
	store %ptr %r101, %ptr* %t11
	%r102 = inttoptr %word 0 to %ptr
	%r103 = load %ptr, %ptr* %t10
	%r104 = inttoptr %word 1 to %ptr
	%r105 = load %ptr, %ptr* %t11
	%r109 = bitcast %ptr %r105 to [0 x %ptr]*
	%r108 = ptrtoint %ptr %r104 to %word
	%r107 = getelementptr [0 x %ptr], [0 x %ptr]* %r109, %word 0, %word %r108
	store %ptr %r103, %ptr* %r107
	%r106 = bitcast %ptr %r103 to %ptr
	store %ptr %r106, %ptr* %t5
	store %ptr %r106, %ptr* %t11
	%r111 = getelementptr %ptr, %ptr* %t10, %word 0
	%r110 = bitcast %ptr* %r111 to %ptr
	%r112 = call %ptr @"gc/pop-root"(%ptr %r110)
	%r113 = load %ptr, %ptr* %t11
	store %ptr %r113, %ptr* %t9
	%r114 = inttoptr %word 0 to %ptr
	%r118 = ptrtoint %ptr %r114 to %word
	%r117 = ptrtoint %ptr %r113 to %word
	%r116 = icmp eq %word %r118, %r117
	%r115 = inttoptr i1 %r116 to %ptr
	%r120 = ptrtoint %ptr %r115 to %word
	%r119 = icmp ne %word %r120, 0
	br i1 %r119, label %L149, label %L144
L149:
	br label %L144
L144:
	%r121 = load %ptr, %ptr* %t9
	%r122 = inttoptr %word 0 to %ptr
	store %ptr %r122, %ptr* %t9
	%r123 = load %ptr, %ptr* %t6
	%r124 = load %ptr, %ptr* %t2
	%r128 = ptrtoint %ptr %r124 to %word
	%r127 = ptrtoint %ptr %r123 to %word
	%r126 = icmp slt %word %r128, %r127
	%r125 = inttoptr i1 %r126 to %ptr
	store %ptr %r125, %ptr* %t9
	%r129 = inttoptr %word 0 to %ptr
	%r133 = ptrtoint %ptr %r129 to %word
	%r132 = ptrtoint %ptr %r125 to %word
	%r131 = icmp eq %word %r133, %r132
	%r130 = inttoptr i1 %r131 to %ptr
	%r135 = ptrtoint %ptr %r130 to %word
	%r134 = icmp ne %word %r135, 0
	br i1 %r134, label %L151, label %L150
L151:
	%r136 = load %ptr, %ptr* %t1
	store %ptr %r136, %ptr* %t10
	%r137 = inttoptr %word 0 to %ptr
	%r138 = inttoptr %word 1 to %ptr
	%r139 = inttoptr %word 1 to %ptr
	%r140 = load %ptr, %ptr* %t2
	%r141 = inttoptr %word 1 to %ptr
	%r145 = ptrtoint %ptr %r141 to %word
	%r144 = ptrtoint %ptr %r140 to %word
	%r143 = add %word %r145, %r144
	%r142 = inttoptr %word %r143 to %ptr
	%r149 = ptrtoint %ptr %r142 to %word
	%r148 = ptrtoint %ptr %r139 to %word
	%r147 = shl %word %r149, %r148
	%r146 = inttoptr %word %r147 to %ptr
	%r153 = ptrtoint %ptr %r146 to %word
	%r152 = ptrtoint %ptr %r138 to %word
	%r151 = add %word %r153, %r152
	%r150 = inttoptr %word %r151 to %ptr
	%r154 = inttoptr %word 0 to %ptr
	%r155 = load %ptr, %ptr* %t10
	%r159 = bitcast %ptr %r155 to [0 x %ptr]*
	%r158 = ptrtoint %ptr %r154 to %word
	%r157 = getelementptr [0 x %ptr], [0 x %ptr]* %r159, %word 0, %word %r158
	store %ptr %r150, %ptr* %r157
	%r156 = bitcast %ptr %r150 to %ptr
	store %ptr %r156, %ptr* %t9
	%r160 = inttoptr %word 0 to %ptr
	%r164 = ptrtoint %ptr %r160 to %word
	%r163 = ptrtoint %ptr %r156 to %word
	%r162 = icmp eq %word %r164, %r163
	%r161 = inttoptr i1 %r162 to %ptr
	%r166 = ptrtoint %ptr %r161 to %word
	%r165 = icmp ne %word %r166, 0
	br i1 %r165, label %L152, label %L150
L152:
	br label %L150
L150:
	%r167 = load %ptr, %ptr* %t9
	%r168 = load %ptr, %ptr* %t3
	%r169 = load %ptr, %ptr* %t2
	%r170 = load %ptr, %ptr* %t5
	%r174 = bitcast %ptr %r170 to [0 x %ptr]*
	%r173 = ptrtoint %ptr %r169 to %word
	%r172 = getelementptr [0 x %ptr], [0 x %ptr]* %r174, %word 0, %word %r173
	store %ptr %r168, %ptr* %r172
	%r171 = bitcast %ptr %r168 to %ptr
	store %ptr %r171, %ptr* %t8
	%r175 = inttoptr %word 0 to %ptr
	%r179 = ptrtoint %ptr %r175 to %word
	%r178 = ptrtoint %ptr %r171 to %word
	%r177 = icmp eq %word %r179, %r178
	%r176 = inttoptr i1 %r177 to %ptr
	%r181 = ptrtoint %ptr %r176 to %word
	%r180 = icmp ne %word %r181, 0
	br i1 %r180, label %L142, label %L153
L153:
	br label %L142
L142:
	%r182 = load %ptr, %ptr* %t8
	store %ptr %r182, %ptr* %t4
	%r183 = inttoptr %word 0 to %ptr
	%r187 = ptrtoint %ptr %r183 to %word
	%r186 = ptrtoint %ptr %r182 to %word
	%r185 = icmp eq %word %r187, %r186
	%r184 = inttoptr i1 %r185 to %ptr
	%r189 = ptrtoint %ptr %r184 to %word
	%r188 = icmp ne %word %r189, 0
	br i1 %r188, label %L140, label %L154
L154:
	br label %L140
L140:
	%r190 = load %ptr, %ptr* %t4
	ret %ptr %r190
}
define %ptr @"k/array-append"(%ptr %array, %ptr %val) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %array, %ptr* %t1
	store %ptr %val, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/array-length"(%ptr %r2)
	%r4 = load %ptr, %ptr* %t2
	%r5 = call %ptr @"k/set-array-at"(%ptr %r1, %ptr %r3, %ptr %r4)
	ret %ptr %r5
}
define %ptr @"k/array-insert"(%ptr %array, %ptr %index, %ptr %value) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %array, %ptr* %t1
	store %ptr %index, %ptr* %t2
	store %ptr %value, %ptr* %t3
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/array-length"(%ptr %r1)
	store %ptr %r2, %ptr* %t4
	%r3 = load %ptr, %ptr* %t1
	%r4 = load %ptr, %ptr* %t3
	%r5 = call %ptr @"k/array-append"(%ptr %r3, %ptr %r4)
	%r6 = inttoptr %word 1 to %ptr
	store %ptr %r6, %ptr* %t5
	%r7 = load %ptr, %ptr* %t4
	%r8 = load %ptr, %ptr* %t2
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = icmp slt %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	store %ptr %r9, %ptr* %t5
	%r13 = inttoptr %word 0 to %ptr
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r9 to %word
	%r15 = icmp eq %word %r17, %r16
	%r14 = inttoptr i1 %r15 to %ptr
	%r19 = ptrtoint %ptr %r14 to %word
	%r18 = icmp ne %word %r19, 0
	br i1 %r18, label %L155, label %L156
L156:
	%r20 = load %ptr, %ptr* %t1
	store %ptr %r20, %ptr* %t6
	%r21 = inttoptr %word 0 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t6
	%r27 = bitcast %ptr %r23 to [0 x %ptr]*
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = getelementptr [0 x %ptr], [0 x %ptr]* %r27, %word 0, %word %r26
	%r24 = load %ptr, %ptr* %r25
	store %ptr %r24, %ptr* %t6
	%r28 = inttoptr %word 4 to %ptr
	%r29 = load %ptr, %ptr* %t2
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = mul %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r34 = load %ptr, %ptr* %t6
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = add %word %r38, %r37
	%r35 = inttoptr %word %r36 to %ptr
	store %ptr %r35, %ptr* %t7
	%r39 = inttoptr %word 4 to %ptr
	%r40 = load %ptr, %ptr* %t7
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = add %word %r44, %r43
	%r41 = inttoptr %word %r42 to %ptr
	%r45 = load %ptr, %ptr* %t7
	%r46 = inttoptr %word 4 to %ptr
	%r47 = load %ptr, %ptr* %t2
	%r48 = load %ptr, %ptr* %t4
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = sub %word %r52, %r51
	%r49 = inttoptr %word %r50 to %ptr
	%r56 = ptrtoint %ptr %r49 to %word
	%r55 = ptrtoint %ptr %r46 to %word
	%r54 = mul %word %r56, %r55
	%r53 = inttoptr %word %r54 to %ptr
	%ffi-cast57 = ptrtoint %ptr %r53 to i32
	%r58 = call %ptr @memmove(%ptr %r41, %ptr %r45, i32 %ffi-cast57)
	store %ptr %r58, %ptr* %t5
	%r59 = inttoptr %word 0 to %ptr
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = ptrtoint %ptr %r58 to %word
	%r61 = icmp eq %word %r63, %r62
	%r60 = inttoptr i1 %r61 to %ptr
	%r65 = ptrtoint %ptr %r60 to %word
	%r64 = icmp ne %word %r65, 0
	br i1 %r64, label %L155, label %L157
L157:
	br label %L155
L155:
	%r66 = load %ptr, %ptr* %t5
	%r67 = load %ptr, %ptr* %t1
	%r68 = load %ptr, %ptr* %t2
	%r69 = load %ptr, %ptr* %t3
	%r70 = call %ptr @"k/set-array-at"(%ptr %r67, %ptr %r68, %ptr %r69)
	ret %ptr %r70
}
define %ptr @"k/concat-list"(%ptr %head, %ptr %tail) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %head, %ptr* %t1
	store %ptr %tail, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"get/type"(%ptr %r1)
	%r3 = inttoptr %word 19 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	%r9 = ptrtoint %ptr %r4 to %word
	%r8 = icmp ne %word %r9, 0
	br i1 %r8, label %L158, label %L159
L158:
	%r10 = inttoptr %word 1 to %ptr
	%r11 = load %ptr, %ptr* %t1
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	%r12 = load %ptr, %ptr* %r13
	%r16 = load %ptr, %ptr* %t2
	%r17 = call %ptr @"k/concat-list"(%ptr %r12, %ptr %r16)
	store %ptr %r17, %ptr* %t4
	%r19 = getelementptr %ptr, %ptr* %t4, %word 0
	%r18 = bitcast %ptr* %r19 to %ptr
	%r20 = call %ptr @"gc/push-root"(%ptr %r18)
	%r21 = inttoptr %word 0 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r27 = load %ptr, %ptr* %t4
	%r28 = call %ptr @"new-<pair>"(%ptr %r23, %ptr %r27)
	store %ptr %r28, %ptr* %t5
	%r30 = getelementptr %ptr, %ptr* %t4, %word 0
	%r29 = bitcast %ptr* %r30 to %ptr
	%r31 = call %ptr @"gc/pop-root"(%ptr %r29)
	%r32 = load %ptr, %ptr* %t5
	store %ptr %r32, %ptr* %t3
	br label %L160
L159:
	%r33 = load %ptr, %ptr* %t2
	store %ptr %r33, %ptr* %t3
	br label %L160
L160:
	%r34 = load %ptr, %ptr* %t3
	ret %ptr %r34
}
define %ptr @"new-<string>-of-length"(%ptr %len) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %len, %ptr* %t1
	%r1 = inttoptr %word 17 to %ptr
	%r2 = inttoptr %word 8 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t2
	%r5 = getelementptr %ptr, %ptr* %t2, %word 0
	%r4 = bitcast %ptr* %r5 to %ptr
	%r6 = call %ptr @"gc/push-root"(%ptr %r4)
	%r7 = load %ptr, %ptr* %t2
	store %ptr %r7, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = inttoptr %word 1 to %ptr
	%r11 = load %ptr, %ptr* %t1
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = shl %word %r15, %r14
	%r12 = inttoptr %word %r13 to %ptr
	%r19 = ptrtoint %ptr %r12 to %word
	%r18 = ptrtoint %ptr %r9 to %word
	%r17 = add %word %r19, %r18
	%r16 = inttoptr %word %r17 to %ptr
	%r20 = inttoptr %word 0 to %ptr
	%r21 = load %ptr, %ptr* %t3
	%r25 = bitcast %ptr %r21 to [0 x %ptr]*
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = getelementptr [0 x %ptr], [0 x %ptr]* %r25, %word 0, %word %r24
	store %ptr %r16, %ptr* %r23
	%r22 = bitcast %ptr %r16 to %ptr
	%r26 = load %ptr, %ptr* %t2
	store %ptr %r26, %ptr* %t3
	%r27 = inttoptr %word 0 to %ptr
	%r28 = inttoptr %word 5 to %ptr
	%r29 = inttoptr %word 4 to %ptr
	%r30 = inttoptr %word 1 to %ptr
	%r31 = load %ptr, %ptr* %t1
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = add %word %r35, %r34
	%r32 = inttoptr %word %r33 to %ptr
	%r39 = ptrtoint %ptr %r32 to %word
	%r38 = ptrtoint %ptr %r29 to %word
	%r37 = mul %word %r39, %r38
	%r36 = inttoptr %word %r37 to %ptr
	%r40 = call %ptr @"%new-object/opaque"(%ptr %r28, %ptr %r36)
	%r41 = inttoptr %word 1 to %ptr
	%r42 = load %ptr, %ptr* %t3
	%r46 = bitcast %ptr %r42 to [0 x %ptr]*
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = getelementptr [0 x %ptr], [0 x %ptr]* %r46, %word 0, %word %r45
	store %ptr %r40, %ptr* %r44
	%r43 = bitcast %ptr %r40 to %ptr
	%r47 = load %ptr, %ptr* %t2
	store %ptr %r47, %ptr* %t3
	%r49 = getelementptr %ptr, %ptr* %t2, %word 0
	%r48 = bitcast %ptr* %r49 to %ptr
	%r50 = call %ptr @"gc/pop-root"(%ptr %r48)
	%r51 = load %ptr, %ptr* %t3
	ret %ptr %r51
}
define %ptr @"new-<string>-from-cstring"(%ptr %cstr) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %cstr, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = call i32 @strlen(%ptr %r1)
	%r3 = inttoptr %word %r2 to %ptr
	store %ptr %r3, %ptr* %t2
	%r4 = load %ptr, %ptr* %t2
	%r5 = call %ptr @"new-<string>-of-length"(%ptr %r4)
	store %ptr %r5, %ptr* %t3
	%r6 = load %ptr, %ptr* %t3
	store %ptr %r6, %ptr* %t4
	%r7 = inttoptr %word 0 to %ptr
	%r8 = inttoptr %word 1 to %ptr
	%r9 = load %ptr, %ptr* %t4
	%r13 = bitcast %ptr %r9 to [0 x %ptr]*
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = getelementptr [0 x %ptr], [0 x %ptr]* %r13, %word 0, %word %r12
	%r10 = load %ptr, %ptr* %r11
	%r14 = load %ptr, %ptr* %t1
	%r15 = load %ptr, %ptr* %t2
	%ffi-cast16 = ptrtoint %ptr %r15 to i32
	%r17 = call %ptr @memcpy(%ptr %r10, %ptr %r14, i32 %ffi-cast16)
	%r18 = load %ptr, %ptr* %t3
	ret %ptr %r18
}
define %ptr @"new-<symbol>"(%ptr %cstr) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %cstr, %ptr* %t1
	%r1 = inttoptr %word 18 to %ptr
	%r2 = inttoptr %word 4 to %ptr
	%r3 = call %ptr @"%new-object/opaque"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t2
	%r4 = load %ptr, %ptr* %t2
	store %ptr %r4, %ptr* %t3
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t1
	%r7 = call %ptr @strdup(%ptr %r6)
	%r8 = inttoptr %word 0 to %ptr
	%r9 = load %ptr, %ptr* %t3
	%r13 = bitcast %ptr %r9 to [0 x %ptr]*
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = getelementptr [0 x %ptr], [0 x %ptr]* %r13, %word 0, %word %r12
	store %ptr %r7, %ptr* %r11
	%r10 = bitcast %ptr %r7 to %ptr
	%r14 = load %ptr, %ptr* %t2
	ret %ptr %r14
}
define %ptr @"new-<array>"(%ptr %size) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %size, %ptr* %t1
	%r1 = inttoptr %word 7 to %ptr
	%r2 = inttoptr %word 8 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t2
	%r5 = getelementptr %ptr, %ptr* %t2, %word 0
	%r4 = bitcast %ptr* %r5 to %ptr
	%r6 = call %ptr @"gc/push-root"(%ptr %r4)
	%r7 = load %ptr, %ptr* %t2
	store %ptr %r7, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = inttoptr %word 1 to %ptr
	%r11 = load %ptr, %ptr* %t1
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = shl %word %r15, %r14
	%r12 = inttoptr %word %r13 to %ptr
	%r19 = ptrtoint %ptr %r12 to %word
	%r18 = ptrtoint %ptr %r9 to %word
	%r17 = add %word %r19, %r18
	%r16 = inttoptr %word %r17 to %ptr
	%r20 = inttoptr %word 0 to %ptr
	%r21 = load %ptr, %ptr* %t3
	%r25 = bitcast %ptr %r21 to [0 x %ptr]*
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = getelementptr [0 x %ptr], [0 x %ptr]* %r25, %word 0, %word %r24
	store %ptr %r16, %ptr* %r23
	%r22 = bitcast %ptr %r16 to %ptr
	%r26 = load %ptr, %ptr* %t2
	store %ptr %r26, %ptr* %t3
	%r27 = inttoptr %word 0 to %ptr
	%r28 = inttoptr %word 5 to %ptr
	%r29 = inttoptr %word 4 to %ptr
	%r30 = inttoptr %word 0 to %ptr
	store %ptr %r30, %ptr* %t4
	%r31 = load %ptr, %ptr* %t1
	store %ptr %r31, %ptr* %t4
	%r32 = inttoptr %word 0 to %ptr
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = icmp eq %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	%r38 = ptrtoint %ptr %r33 to %word
	%r37 = icmp ne %word %r38, 0
	br i1 %r37, label %L162, label %L161
L162:
	%r39 = inttoptr %word 1 to %ptr
	store %ptr %r39, %ptr* %t4
	%r40 = inttoptr %word 0 to %ptr
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = icmp eq %word %r44, %r43
	%r41 = inttoptr i1 %r42 to %ptr
	%r46 = ptrtoint %ptr %r41 to %word
	%r45 = icmp ne %word %r46, 0
	br i1 %r45, label %L163, label %L161
L163:
	br label %L161
L161:
	%r47 = load %ptr, %ptr* %t4
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r29 to %word
	%r49 = mul %word %r51, %r50
	%r48 = inttoptr %word %r49 to %ptr
	%r52 = call %ptr @"%new-object"(%ptr %r28, %ptr %r48)
	%r53 = inttoptr %word 1 to %ptr
	%r54 = load %ptr, %ptr* %t3
	%r58 = bitcast %ptr %r54 to [0 x %ptr]*
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = getelementptr [0 x %ptr], [0 x %ptr]* %r58, %word 0, %word %r57
	store %ptr %r52, %ptr* %r56
	%r55 = bitcast %ptr %r52 to %ptr
	%r59 = load %ptr, %ptr* %t2
	store %ptr %r59, %ptr* %t3
	%r61 = getelementptr %ptr, %ptr* %t2, %word 0
	%r60 = bitcast %ptr* %r61 to %ptr
	%r62 = call %ptr @"gc/pop-root"(%ptr %r60)
	%r63 = load %ptr, %ptr* %t3
	ret %ptr %r63
}
define %ptr @"new-<expr>"(%ptr %defn, %ptr %ctx) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %defn, %ptr* %t1
	store %ptr %ctx, %ptr* %t2
	%r1 = inttoptr %word 8 to %ptr
	%r2 = inttoptr %word 12 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t1
	%r7 = inttoptr %word 1 to %ptr
	%r8 = load %ptr, %ptr* %t4
	%r12 = bitcast %ptr %r8 to [0 x %ptr]*
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = getelementptr [0 x %ptr], [0 x %ptr]* %r12, %word 0, %word %r11
	store %ptr %r6, %ptr* %r10
	%r9 = bitcast %ptr %r6 to %ptr
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t4
	%r14 = inttoptr %word 0 to %ptr
	%r15 = load %ptr, %ptr* %t2
	%r16 = inttoptr %word 2 to %ptr
	%r17 = load %ptr, %ptr* %t4
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	store %ptr %r15, %ptr* %r19
	%r18 = bitcast %ptr %r15 to %ptr
	%r22 = load %ptr, %ptr* %t3
	ret %ptr %r22
}
define %ptr @"new-<form>"(%ptr %fn, %ptr %sym) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %fn, %ptr* %t1
	store %ptr %sym, %ptr* %t2
	%r1 = inttoptr %word 9 to %ptr
	%r2 = inttoptr %word 8 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t1
	%r7 = inttoptr %word 0 to %ptr
	%r8 = load %ptr, %ptr* %t4
	%r12 = bitcast %ptr %r8 to [0 x %ptr]*
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = getelementptr [0 x %ptr], [0 x %ptr]* %r12, %word 0, %word %r11
	store %ptr %r6, %ptr* %r10
	%r9 = bitcast %ptr %r6 to %ptr
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t4
	%r14 = inttoptr %word 0 to %ptr
	%r15 = load %ptr, %ptr* %t2
	%r16 = inttoptr %word 1 to %ptr
	%r17 = load %ptr, %ptr* %t4
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	store %ptr %r15, %ptr* %r19
	%r18 = bitcast %ptr %r15 to %ptr
	%r22 = load %ptr, %ptr* %t3
	ret %ptr %r22
}
define %ptr @"new-<fixed>"(%ptr %fn) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %fn, %ptr* %t1
	%r1 = inttoptr %word 10 to %ptr
	%r2 = inttoptr %word 4 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t2
	%r4 = load %ptr, %ptr* %t2
	store %ptr %r4, %ptr* %t3
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t1
	%r7 = inttoptr %word 0 to %ptr
	%r8 = load %ptr, %ptr* %t3
	%r12 = bitcast %ptr %r8 to [0 x %ptr]*
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = getelementptr [0 x %ptr], [0 x %ptr]* %r12, %word 0, %word %r11
	store %ptr %r6, %ptr* %r10
	%r9 = bitcast %ptr %r6 to %ptr
	%r13 = load %ptr, %ptr* %t2
	ret %ptr %r13
}
define %ptr @"new-<subr>"(%ptr %_imp, %ptr %_name) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %_imp, %ptr* %t1
	store %ptr %_name, %ptr* %t2
	%r1 = inttoptr %word 11 to %ptr
	%r2 = inttoptr %word 16 to %ptr
	%r3 = call %ptr @"%new-object/opaque"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t1
	%r7 = inttoptr %word 1 to %ptr
	%r8 = load %ptr, %ptr* %t4
	%r12 = bitcast %ptr %r8 to [0 x %ptr]*
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = getelementptr [0 x %ptr], [0 x %ptr]* %r12, %word 0, %word %r11
	store %ptr %r6, %ptr* %r10
	%r9 = bitcast %ptr %r6 to %ptr
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t4
	%r14 = inttoptr %word 0 to %ptr
	%r15 = load %ptr, %ptr* %t2
	%r16 = inttoptr %word 0 to %ptr
	%r17 = load %ptr, %ptr* %t4
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	store %ptr %r15, %ptr* %r19
	%r18 = bitcast %ptr %r15 to %ptr
	%r22 = load %ptr, %ptr* %t3
	ret %ptr %r22
}
define %ptr @"new-<variable>"(%ptr %name, %ptr %value, %ptr %env, %ptr %index) {
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %name, %ptr* %t1
	store %ptr %value, %ptr* %t2
	store %ptr %env, %ptr* %t3
	store %ptr %index, %ptr* %t4
	%r1 = inttoptr %word 12 to %ptr
	%r2 = inttoptr %word 16 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t5
	%r5 = getelementptr %ptr, %ptr* %t5, %word 0
	%r4 = bitcast %ptr* %r5 to %ptr
	%r6 = call %ptr @"gc/push-root"(%ptr %r4)
	%r7 = load %ptr, %ptr* %t5
	store %ptr %r7, %ptr* %t6
	%r8 = inttoptr %word 0 to %ptr
	%r9 = load %ptr, %ptr* %t1
	%r10 = inttoptr %word 0 to %ptr
	%r11 = load %ptr, %ptr* %t6
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	store %ptr %r9, %ptr* %r13
	%r12 = bitcast %ptr %r9 to %ptr
	%r16 = load %ptr, %ptr* %t5
	store %ptr %r16, %ptr* %t6
	%r17 = inttoptr %word 0 to %ptr
	%r18 = load %ptr, %ptr* %t2
	%r19 = inttoptr %word 1 to %ptr
	%r20 = load %ptr, %ptr* %t6
	%r24 = bitcast %ptr %r20 to [0 x %ptr]*
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = getelementptr [0 x %ptr], [0 x %ptr]* %r24, %word 0, %word %r23
	store %ptr %r18, %ptr* %r22
	%r21 = bitcast %ptr %r18 to %ptr
	%r25 = load %ptr, %ptr* %t5
	store %ptr %r25, %ptr* %t6
	%r26 = inttoptr %word 0 to %ptr
	%r27 = load %ptr, %ptr* %t3
	%r28 = inttoptr %word 2 to %ptr
	%r29 = load %ptr, %ptr* %t6
	%r33 = bitcast %ptr %r29 to [0 x %ptr]*
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = getelementptr [0 x %ptr], [0 x %ptr]* %r33, %word 0, %word %r32
	store %ptr %r27, %ptr* %r31
	%r30 = bitcast %ptr %r27 to %ptr
	%r34 = load %ptr, %ptr* %t5
	store %ptr %r34, %ptr* %t6
	%r35 = inttoptr %word 0 to %ptr
	%r36 = inttoptr %word 1 to %ptr
	%r37 = inttoptr %word 1 to %ptr
	%r38 = load %ptr, %ptr* %t4
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = shl %word %r42, %r41
	%r39 = inttoptr %word %r40 to %ptr
	%r46 = ptrtoint %ptr %r39 to %word
	%r45 = ptrtoint %ptr %r36 to %word
	%r44 = add %word %r46, %r45
	%r43 = inttoptr %word %r44 to %ptr
	%r47 = inttoptr %word 3 to %ptr
	%r48 = load %ptr, %ptr* %t6
	%r52 = bitcast %ptr %r48 to [0 x %ptr]*
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = getelementptr [0 x %ptr], [0 x %ptr]* %r52, %word 0, %word %r51
	store %ptr %r43, %ptr* %r50
	%r49 = bitcast %ptr %r43 to %ptr
	%r53 = load %ptr, %ptr* %t5
	store %ptr %r53, %ptr* %t6
	%r55 = getelementptr %ptr, %ptr* %t5, %word 0
	%r54 = bitcast %ptr* %r55 to %ptr
	%r56 = call %ptr @"gc/pop-root"(%ptr %r54)
	%r57 = load %ptr, %ptr* %t6
	ret %ptr %r57
}
define %ptr @"new-<env>"(%ptr %parent, %ptr %level, %ptr %offset) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %parent, %ptr* %t1
	store %ptr %level, %ptr* %t2
	store %ptr %offset, %ptr* %t3
	%r1 = inttoptr %word 13 to %ptr
	%r2 = inttoptr %word 20 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t4
	%r5 = getelementptr %ptr, %ptr* %t4, %word 0
	%r4 = bitcast %ptr* %r5 to %ptr
	%r6 = call %ptr @"gc/push-root"(%ptr %r4)
	%r7 = load %ptr, %ptr* %t4
	store %ptr %r7, %ptr* %t5
	%r8 = inttoptr %word 0 to %ptr
	%r9 = load %ptr, %ptr* %t1
	%r10 = inttoptr %word 0 to %ptr
	%r11 = load %ptr, %ptr* %t5
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	store %ptr %r9, %ptr* %r13
	%r12 = bitcast %ptr %r9 to %ptr
	%r16 = load %ptr, %ptr* %t4
	store %ptr %r16, %ptr* %t5
	%r17 = inttoptr %word 0 to %ptr
	%r18 = inttoptr %word 1 to %ptr
	%r19 = inttoptr %word 1 to %ptr
	%r20 = load %ptr, %ptr* %t1
	%r22 = ptrtoint %ptr %r20 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L164, label %L165
L164:
	%r23 = load %ptr, %ptr* %t2
	%r24 = inttoptr %word 1 to %ptr
	%r25 = load %ptr, %ptr* %t1
	store %ptr %r25, %ptr* %t7
	%r26 = inttoptr %word 0 to %ptr
	%r27 = inttoptr %word 1 to %ptr
	%r28 = load %ptr, %ptr* %t7
	%r32 = bitcast %ptr %r28 to [0 x %ptr]*
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = getelementptr [0 x %ptr], [0 x %ptr]* %r32, %word 0, %word %r31
	%r29 = load %ptr, %ptr* %r30
	%r36 = ptrtoint %ptr %r29 to %word
	%r35 = ptrtoint %ptr %r24 to %word
	%r34 = ashr %word %r36, %r35
	%r33 = inttoptr %word %r34 to %ptr
	%r40 = ptrtoint %ptr %r33 to %word
	%r39 = ptrtoint %ptr %r23 to %word
	%r38 = add %word %r40, %r39
	%r37 = inttoptr %word %r38 to %ptr
	store %ptr %r37, %ptr* %t6
	br label %L166
L165:
	%r41 = inttoptr %word 0 to %ptr
	store %ptr %r41, %ptr* %t6
	br label %L166
L166:
	%r42 = load %ptr, %ptr* %t6
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = ptrtoint %ptr %r19 to %word
	%r44 = shl %word %r46, %r45
	%r43 = inttoptr %word %r44 to %ptr
	%r50 = ptrtoint %ptr %r43 to %word
	%r49 = ptrtoint %ptr %r18 to %word
	%r48 = add %word %r50, %r49
	%r47 = inttoptr %word %r48 to %ptr
	%r51 = inttoptr %word 1 to %ptr
	%r52 = load %ptr, %ptr* %t5
	%r56 = bitcast %ptr %r52 to [0 x %ptr]*
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = getelementptr [0 x %ptr], [0 x %ptr]* %r56, %word 0, %word %r55
	store %ptr %r47, %ptr* %r54
	%r53 = bitcast %ptr %r47 to %ptr
	%r57 = load %ptr, %ptr* %t4
	store %ptr %r57, %ptr* %t5
	%r58 = inttoptr %word 0 to %ptr
	%r59 = inttoptr %word 1 to %ptr
	%r60 = inttoptr %word 1 to %ptr
	%r61 = load %ptr, %ptr* %t3
	%r65 = ptrtoint %ptr %r61 to %word
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = shl %word %r65, %r64
	%r62 = inttoptr %word %r63 to %ptr
	%r69 = ptrtoint %ptr %r62 to %word
	%r68 = ptrtoint %ptr %r59 to %word
	%r67 = add %word %r69, %r68
	%r66 = inttoptr %word %r67 to %ptr
	%r70 = inttoptr %word 2 to %ptr
	%r71 = load %ptr, %ptr* %t5
	%r75 = bitcast %ptr %r71 to [0 x %ptr]*
	%r74 = ptrtoint %ptr %r70 to %word
	%r73 = getelementptr [0 x %ptr], [0 x %ptr]* %r75, %word 0, %word %r74
	store %ptr %r66, %ptr* %r73
	%r72 = bitcast %ptr %r66 to %ptr
	%r76 = load %ptr, %ptr* %t4
	store %ptr %r76, %ptr* %t5
	%r77 = inttoptr %word 0 to %ptr
	%r78 = inttoptr %word 0 to %ptr
	%r79 = call %ptr @"new-<array>"(%ptr %r78)
	%r80 = inttoptr %word 3 to %ptr
	%r81 = load %ptr, %ptr* %t5
	%r85 = bitcast %ptr %r81 to [0 x %ptr]*
	%r84 = ptrtoint %ptr %r80 to %word
	%r83 = getelementptr [0 x %ptr], [0 x %ptr]* %r85, %word 0, %word %r84
	store %ptr %r79, %ptr* %r83
	%r82 = bitcast %ptr %r79 to %ptr
	%r86 = load %ptr, %ptr* %t4
	store %ptr %r86, %ptr* %t5
	%r88 = getelementptr %ptr, %ptr* %t4, %word 0
	%r87 = bitcast %ptr* %r88 to %ptr
	%r89 = call %ptr @"gc/pop-root"(%ptr %r87)
	%r90 = load %ptr, %ptr* %t5
	ret %ptr %r90
}
define %ptr @"new-base-<context>"(%ptr %home, %ptr %caller, %ptr %env) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %home, %ptr* %t1
	store %ptr %caller, %ptr* %t2
	store %ptr %env, %ptr* %t3
	%r1 = inttoptr %word 14 to %ptr
	%r2 = inttoptr %word 20 to %ptr
	%r3 = call %ptr @"%new-object"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t4
	%r5 = getelementptr %ptr, %ptr* %t4, %word 0
	%r4 = bitcast %ptr* %r5 to %ptr
	%r6 = call %ptr @"gc/push-root"(%ptr %r4)
	%r7 = load %ptr, %ptr* %t4
	store %ptr %r7, %ptr* %t5
	%r8 = inttoptr %word 0 to %ptr
	%r9 = load %ptr, %ptr* %t1
	%r10 = inttoptr %word 0 to %ptr
	%r11 = load %ptr, %ptr* %t5
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	store %ptr %r9, %ptr* %r13
	%r12 = bitcast %ptr %r9 to %ptr
	%r16 = load %ptr, %ptr* %t4
	store %ptr %r16, %ptr* %t5
	%r17 = inttoptr %word 0 to %ptr
	%r18 = load %ptr, %ptr* %t3
	%r19 = inttoptr %word 1 to %ptr
	%r20 = load %ptr, %ptr* %t5
	%r24 = bitcast %ptr %r20 to [0 x %ptr]*
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = getelementptr [0 x %ptr], [0 x %ptr]* %r24, %word 0, %word %r23
	store %ptr %r18, %ptr* %r22
	%r21 = bitcast %ptr %r18 to %ptr
	%r25 = load %ptr, %ptr* %t4
	store %ptr %r25, %ptr* %t5
	%r26 = inttoptr %word 0 to %ptr
	%r27 = inttoptr %word 0 to %ptr
	%r28 = call %ptr @"new-<array>"(%ptr %r27)
	%r29 = inttoptr %word 2 to %ptr
	%r30 = load %ptr, %ptr* %t5
	%r34 = bitcast %ptr %r30 to [0 x %ptr]*
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = getelementptr [0 x %ptr], [0 x %ptr]* %r34, %word 0, %word %r33
	store %ptr %r28, %ptr* %r32
	%r31 = bitcast %ptr %r28 to %ptr
	%r35 = load %ptr, %ptr* %t4
	store %ptr %r35, %ptr* %t5
	%r37 = getelementptr %ptr, %ptr* %t4, %word 0
	%r36 = bitcast %ptr* %r37 to %ptr
	%r38 = call %ptr @"gc/pop-root"(%ptr %r36)
	%r39 = load %ptr, %ptr* %t5
	ret %ptr %r39
}
define %ptr @"new-<context>"(%ptr %home, %ptr %caller, %ptr %env) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %home, %ptr* %t1
	store %ptr %caller, %ptr* %t2
	store %ptr %env, %ptr* %t3
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t4
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t6
	%r3 = load %ptr, %ptr* %t2
	store %ptr %r3, %ptr* %t6
	%r4 = inttoptr %word 0 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	%r10 = ptrtoint %ptr %r5 to %word
	%r9 = icmp ne %word %r10, 0
	br i1 %r9, label %L170, label %L171
L171:
	%r11 = load %ptr, %ptr* %t2
	store %ptr %r11, %ptr* %t7
	%r12 = inttoptr %word 0 to %ptr
	%r13 = inttoptr %word 3 to %ptr
	%r14 = load %ptr, %ptr* %t7
	%r18 = bitcast %ptr %r14 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	store %ptr %r15, %ptr* %t6
	%r19 = inttoptr %word 0 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r15 to %word
	%r21 = icmp eq %word %r23, %r22
	%r20 = inttoptr i1 %r21 to %ptr
	%r25 = ptrtoint %ptr %r20 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L170, label %L172
L172:
	br label %L170
L170:
	%r26 = load %ptr, %ptr* %t6
	%r28 = ptrtoint %ptr %r26 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L167, label %L168
L167:
	%r29 = load %ptr, %ptr* %t4
	store %ptr %r29, %ptr* %t6
	%r30 = inttoptr %word 0 to %ptr
	%r31 = load %ptr, %ptr* %t1
	%r32 = inttoptr %word 0 to %ptr
	%r33 = load %ptr, %ptr* %t6
	%r37 = bitcast %ptr %r33 to [0 x %ptr]*
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = getelementptr [0 x %ptr], [0 x %ptr]* %r37, %word 0, %word %r36
	store %ptr %r31, %ptr* %r35
	%r34 = bitcast %ptr %r31 to %ptr
	%r38 = load %ptr, %ptr* %t4
	store %ptr %r38, %ptr* %t6
	%r39 = inttoptr %word 0 to %ptr
	%r40 = load %ptr, %ptr* %t3
	%r41 = inttoptr %word 1 to %ptr
	%r42 = load %ptr, %ptr* %t6
	%r46 = bitcast %ptr %r42 to [0 x %ptr]*
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = getelementptr [0 x %ptr], [0 x %ptr]* %r46, %word 0, %word %r45
	store %ptr %r40, %ptr* %r44
	%r43 = bitcast %ptr %r40 to %ptr
	store %ptr %r43, %ptr* %t5
	br label %L169
L168:
	%r47 = load %ptr, %ptr* %t1
	%r48 = load %ptr, %ptr* %t2
	%r49 = load %ptr, %ptr* %t3
	%r50 = call %ptr @"new-base-<context>"(%ptr %r47, %ptr %r48, %ptr %r49)
	store %ptr %r50, %ptr* %t4
	%r51 = inttoptr %word 1 to %ptr
	store %ptr %r51, %ptr* %t6
	%r52 = load %ptr, %ptr* %t2
	store %ptr %r52, %ptr* %t6
	%r53 = inttoptr %word 0 to %ptr
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = icmp eq %word %r57, %r56
	%r54 = inttoptr i1 %r55 to %ptr
	%r59 = ptrtoint %ptr %r54 to %word
	%r58 = icmp ne %word %r59, 0
	br i1 %r58, label %L173, label %L174
L174:
	%r60 = load %ptr, %ptr* %t2
	store %ptr %r60, %ptr* %t7
	%r61 = inttoptr %word 0 to %ptr
	%r62 = load %ptr, %ptr* %t4
	%r63 = inttoptr %word 3 to %ptr
	%r64 = load %ptr, %ptr* %t7
	%r68 = bitcast %ptr %r64 to [0 x %ptr]*
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = getelementptr [0 x %ptr], [0 x %ptr]* %r68, %word 0, %word %r67
	store %ptr %r62, %ptr* %r66
	%r65 = bitcast %ptr %r62 to %ptr
	store %ptr %r65, %ptr* %t6
	%r69 = inttoptr %word 0 to %ptr
	%r73 = ptrtoint %ptr %r69 to %word
	%r72 = ptrtoint %ptr %r65 to %word
	%r71 = icmp eq %word %r73, %r72
	%r70 = inttoptr i1 %r71 to %ptr
	%r75 = ptrtoint %ptr %r70 to %word
	%r74 = icmp ne %word %r75, 0
	br i1 %r74, label %L173, label %L175
L175:
	br label %L173
L173:
	%r76 = load %ptr, %ptr* %t6
	store %ptr %r76, %ptr* %t5
	br label %L169
L169:
	%r77 = load %ptr, %ptr* %t5
	%r78 = load %ptr, %ptr* %t4
	ret %ptr %r78
}
define %ptr @"global-variable?"(%ptr %var) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %var, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	store %ptr %r1, %ptr* %t2
	%r2 = inttoptr %word 0 to %ptr
	%r3 = inttoptr %word 2 to %ptr
	%r4 = load %ptr, %ptr* %t2
	%r8 = bitcast %ptr %r4 to [0 x %ptr]*
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = getelementptr [0 x %ptr], [0 x %ptr]* %r8, %word 0, %word %r7
	%r5 = load %ptr, %ptr* %r6
	store %ptr %r5, %ptr* %t2
	%r9 = inttoptr %word 1 to %ptr
	store %ptr %r9, %ptr* %t3
	%r10 = load %ptr, %ptr* %t2
	store %ptr %r10, %ptr* %t3
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L176, label %L177
L177:
	%r18 = inttoptr %word 1 to %ptr
	%r19 = load %ptr, %ptr* %t2
	store %ptr %r19, %ptr* %t4
	%r20 = inttoptr %word 0 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t4
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r30 = ptrtoint %ptr %r23 to %word
	%r29 = ptrtoint %ptr %r18 to %word
	%r28 = ashr %word %r30, %r29
	%r27 = inttoptr %word %r28 to %ptr
	%r31 = inttoptr %word 0 to %ptr
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r27 to %word
	%r33 = icmp eq %word %r35, %r34
	%r32 = inttoptr i1 %r33 to %ptr
	store %ptr %r32, %ptr* %t3
	%r36 = inttoptr %word 0 to %ptr
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r32 to %word
	%r38 = icmp eq %word %r40, %r39
	%r37 = inttoptr i1 %r38 to %ptr
	%r42 = ptrtoint %ptr %r37 to %word
	%r41 = icmp ne %word %r42, 0
	br i1 %r41, label %L176, label %L178
L178:
	br label %L176
L176:
	%r43 = load %ptr, %ptr* %t3
	ret %ptr %r43
}
define %ptr @"k/env/lookup-variable"(%ptr %env, %ptr %name) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	store %ptr %env, %ptr* %t1
	store %ptr %name, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	br label %L180
L179:
	%r3 = load %ptr, %ptr* %t1
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	%r5 = inttoptr %word 3 to %ptr
	%r6 = load %ptr, %ptr* %t3
	%r10 = bitcast %ptr %r6 to [0 x %ptr]*
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = getelementptr [0 x %ptr], [0 x %ptr]* %r10, %word 0, %word %r9
	%r7 = load %ptr, %ptr* %r8
	store %ptr %r7, %ptr* %t3
	%r11 = load %ptr, %ptr* %t3
	%r12 = call %ptr @"k/array-length"(%ptr %r11)
	store %ptr %r12, %ptr* %t4
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t5
	%r14 = inttoptr %word 0 to %ptr
	%r15 = inttoptr %word 1 to %ptr
	%r16 = load %ptr, %ptr* %t5
	%r20 = bitcast %ptr %r16 to [0 x %ptr]*
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = getelementptr [0 x %ptr], [0 x %ptr]* %r20, %word 0, %word %r19
	%r17 = load %ptr, %ptr* %r18
	store %ptr %r17, %ptr* %t5
	br label %L183
L182:
	%r21 = load %ptr, %ptr* %t4
	%r22 = load %ptr, %ptr* %t5
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	store %ptr %r23, %ptr* %t6
	%r27 = inttoptr %word 1 to %ptr
	store %ptr %r27, %ptr* %t7
	%r28 = load %ptr, %ptr* %t6
	store %ptr %r28, %ptr* %t8
	%r29 = inttoptr %word 0 to %ptr
	%r30 = inttoptr %word 0 to %ptr
	%r31 = load %ptr, %ptr* %t8
	%r35 = bitcast %ptr %r31 to [0 x %ptr]*
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = getelementptr [0 x %ptr], [0 x %ptr]* %r35, %word 0, %word %r34
	%r32 = load %ptr, %ptr* %r33
	%r36 = load %ptr, %ptr* %t2
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r32 to %word
	%r38 = icmp eq %word %r40, %r39
	%r37 = inttoptr i1 %r38 to %ptr
	store %ptr %r37, %ptr* %t7
	%r41 = inttoptr %word 0 to %ptr
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = ptrtoint %ptr %r37 to %word
	%r43 = icmp eq %word %r45, %r44
	%r42 = inttoptr i1 %r43 to %ptr
	%r47 = ptrtoint %ptr %r42 to %word
	%r46 = icmp ne %word %r47, 0
	br i1 %r46, label %L185, label %L186
L186:
	%r48 = load %ptr, %ptr* %t6
	ret %ptr %r48
	store %ptr %r48, %ptr* %t7
	%r50 = inttoptr %word 0 to %ptr
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = ptrtoint %ptr %r48 to %word
	%r52 = icmp eq %word %r54, %r53
	%r51 = inttoptr i1 %r52 to %ptr
	%r56 = ptrtoint %ptr %r51 to %word
	%r55 = icmp ne %word %r56, 0
	br i1 %r55, label %L185, label %L187
L187:
	br label %L185
L185:
	%r57 = load %ptr, %ptr* %t7
	br label %L183
L183:
	%r58 = inttoptr %word 1 to %ptr
	%r59 = load %ptr, %ptr* %t4
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = ptrtoint %ptr %r58 to %word
	%r61 = sub %word %r63, %r62
	%r60 = inttoptr %word %r61 to %ptr
	store %ptr %r60, %ptr* %t4
	%r64 = inttoptr %word 0 to %ptr
	%r68 = ptrtoint %ptr %r64 to %word
	%r67 = ptrtoint %ptr %r60 to %word
	%r66 = icmp sle %word %r68, %r67
	%r65 = inttoptr i1 %r66 to %ptr
	%r70 = ptrtoint %ptr %r65 to %word
	%r69 = icmp ne %word %r70, 0
	br i1 %r69, label %L182, label %L184
L184:
	%r71 = load %ptr, %ptr* %t1
	store %ptr %r71, %ptr* %t3
	%r72 = inttoptr %word 0 to %ptr
	%r73 = inttoptr %word 0 to %ptr
	%r74 = load %ptr, %ptr* %t3
	%r78 = bitcast %ptr %r74 to [0 x %ptr]*
	%r77 = ptrtoint %ptr %r73 to %word
	%r76 = getelementptr [0 x %ptr], [0 x %ptr]* %r78, %word 0, %word %r77
	%r75 = load %ptr, %ptr* %r76
	store %ptr %r75, %ptr* %t1
	br label %L180
L180:
	%r79 = load %ptr, %ptr* %t1
	%r81 = ptrtoint %ptr %r79 to %word
	%r80 = icmp ne %word %r81, 0
	br i1 %r80, label %L179, label %L181
L181:
	ret %ptr %r79
}
@str193 = private unnamed_addr constant [43 x i8] c"k/env/lookup-variable-or-die failed for %s\00"
define %ptr @"k/env/lookup-variable-or-die"(%ptr %env, %ptr %name) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %env, %ptr* %t1
	store %ptr %name, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = load %ptr, %ptr* %t2
	%r3 = call %ptr @"k/env/lookup-variable"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 1 to %ptr
	store %ptr %r5, %ptr* %t5
	%r6 = load %ptr, %ptr* %t3
	store %ptr %r6, %ptr* %t5
	%r7 = inttoptr %word 0 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	%r13 = ptrtoint %ptr %r8 to %word
	%r12 = icmp ne %word %r13, 0
	br i1 %r12, label %L189, label %L190
L190:
	%r14 = load %ptr, %ptr* %t3
	%r15 = call %ptr @"get/type"(%ptr %r14)
	%r16 = inttoptr %word 12 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	store %ptr %r17, %ptr* %t5
	%r21 = inttoptr %word 0 to %ptr
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r25, %r24
	%r22 = inttoptr i1 %r23 to %ptr
	%r27 = ptrtoint %ptr %r22 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L189, label %L191
L191:
	br label %L189
L189:
	%r28 = load %ptr, %ptr* %t5
	store %ptr %r28, %ptr* %t4
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	%r35 = ptrtoint %ptr %r30 to %word
	%r34 = icmp ne %word %r35, 0
	br i1 %r34, label %L192, label %L188
L192:
	%r36 = getelementptr [43 x i8], [43 x i8]* @str193, %word 0, %word 0
	%r38 = load %ptr, %ptr* %t2
	store %ptr %r38, %ptr* %t5
	%r39 = inttoptr %word 0 to %ptr
	%r40 = inttoptr %word 0 to %ptr
	%r41 = load %ptr, %ptr* %t5
	%r45 = bitcast %ptr %r41 to [0 x %ptr]*
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = getelementptr [0 x %ptr], [0 x %ptr]* %r45, %word 0, %word %r44
	%r42 = load %ptr, %ptr* %r43
	%r46 = call %ptr @fatal1(%ptr %r36, %ptr %r42)
	store %ptr %r46, %ptr* %t4
	%r47 = inttoptr %word 0 to %ptr
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r46 to %word
	%r49 = icmp eq %word %r51, %r50
	%r48 = inttoptr i1 %r49 to %ptr
	%r53 = ptrtoint %ptr %r48 to %word
	%r52 = icmp ne %word %r53, 0
	br i1 %r52, label %L194, label %L188
L194:
	br label %L188
L188:
	%r54 = load %ptr, %ptr* %t4
	%r55 = load %ptr, %ptr* %t3
	ret %ptr %r55
}
@str198 = private unnamed_addr constant [45 x i8] c"undefined variable in env/variable-value: %s\00"
define %ptr @"k/env/variable-value"(%ptr %env, %ptr %name) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %env, %ptr* %t1
	store %ptr %name, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = load %ptr, %ptr* %t2
	%r3 = call %ptr @"k/env/lookup-variable"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	%r6 = ptrtoint %ptr %r4 to %word
	%r5 = icmp ne %word %r6, 0
	br i1 %r5, label %L195, label %L196
L195:
	%r7 = load %ptr, %ptr* %t3
	store %ptr %r7, %ptr* %t5
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t5
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	store %ptr %r11, %ptr* %t4
	br label %L197
L196:
	%r15 = getelementptr [45 x i8], [45 x i8]* @str198, %word 0, %word 0
	%r17 = load %ptr, %ptr* %t2
	store %ptr %r17, %ptr* %t5
	%r18 = inttoptr %word 0 to %ptr
	%r19 = inttoptr %word 0 to %ptr
	%r20 = load %ptr, %ptr* %t5
	%r24 = bitcast %ptr %r20 to [0 x %ptr]*
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = getelementptr [0 x %ptr], [0 x %ptr]* %r24, %word 0, %word %r23
	%r21 = load %ptr, %ptr* %r22
	%r25 = call %ptr @fatal1(%ptr %r15, %ptr %r21)
	store %ptr %r25, %ptr* %t4
	br label %L197
L197:
	%r26 = load %ptr, %ptr* %t4
	ret %ptr %r26
}
define %ptr @"k/env/ensure-variable"(%ptr %env, %ptr %name) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %env, %ptr* %t1
	store %ptr %name, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	%r5 = inttoptr %word 3 to %ptr
	%r6 = load %ptr, %ptr* %t3
	%r10 = bitcast %ptr %r6 to [0 x %ptr]*
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = getelementptr [0 x %ptr], [0 x %ptr]* %r10, %word 0, %word %r9
	%r7 = load %ptr, %ptr* %r8
	store %ptr %r7, %ptr* %t3
	%r11 = load %ptr, %ptr* %t3
	%r12 = call %ptr @"k/array-length"(%ptr %r11)
	store %ptr %r12, %ptr* %t4
	br label %L200
L199:
	%r13 = load %ptr, %ptr* %t3
	%r14 = load %ptr, %ptr* %t4
	%r15 = call %ptr @"k/array-at"(%ptr %r13, %ptr %r14)
	store %ptr %r15, %ptr* %t5
	%r16 = inttoptr %word 1 to %ptr
	store %ptr %r16, %ptr* %t6
	%r17 = load %ptr, %ptr* %t5
	store %ptr %r17, %ptr* %t7
	%r18 = inttoptr %word 0 to %ptr
	%r19 = inttoptr %word 0 to %ptr
	%r20 = load %ptr, %ptr* %t7
	%r24 = bitcast %ptr %r20 to [0 x %ptr]*
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = getelementptr [0 x %ptr], [0 x %ptr]* %r24, %word 0, %word %r23
	%r21 = load %ptr, %ptr* %r22
	%r25 = load %ptr, %ptr* %t2
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = ptrtoint %ptr %r21 to %word
	%r27 = icmp eq %word %r29, %r28
	%r26 = inttoptr i1 %r27 to %ptr
	store %ptr %r26, %ptr* %t6
	%r30 = inttoptr %word 0 to %ptr
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r26 to %word
	%r32 = icmp eq %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	%r36 = ptrtoint %ptr %r31 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L202, label %L203
L203:
	%r37 = load %ptr, %ptr* %t5
	ret %ptr %r37
	store %ptr %r37, %ptr* %t6
	%r39 = inttoptr %word 0 to %ptr
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r37 to %word
	%r41 = icmp eq %word %r43, %r42
	%r40 = inttoptr i1 %r41 to %ptr
	%r45 = ptrtoint %ptr %r40 to %word
	%r44 = icmp ne %word %r45, 0
	br i1 %r44, label %L202, label %L204
L204:
	br label %L202
L202:
	%r46 = load %ptr, %ptr* %t6
	br label %L200
L200:
	%r47 = inttoptr %word 1 to %ptr
	%r48 = load %ptr, %ptr* %t4
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = sub %word %r52, %r51
	%r49 = inttoptr %word %r50 to %ptr
	store %ptr %r49, %ptr* %t4
	%r53 = inttoptr %word 0 to %ptr
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = ptrtoint %ptr %r49 to %word
	%r55 = icmp sle %word %r57, %r56
	%r54 = inttoptr i1 %r55 to %ptr
	%r59 = ptrtoint %ptr %r54 to %word
	%r58 = icmp ne %word %r59, 0
	br i1 %r58, label %L199, label %L201
L201:
	%r60 = inttoptr %word 1 to %ptr
	%r61 = load %ptr, %ptr* %t1
	store %ptr %r61, %ptr* %t5
	%r62 = inttoptr %word 0 to %ptr
	%r63 = inttoptr %word 2 to %ptr
	%r64 = load %ptr, %ptr* %t5
	%r68 = bitcast %ptr %r64 to [0 x %ptr]*
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = getelementptr [0 x %ptr], [0 x %ptr]* %r68, %word 0, %word %r67
	%r65 = load %ptr, %ptr* %r66
	%r72 = ptrtoint %ptr %r65 to %word
	%r71 = ptrtoint %ptr %r60 to %word
	%r70 = ashr %word %r72, %r71
	%r69 = inttoptr %word %r70 to %ptr
	store %ptr %r69, %ptr* %t5
	%r73 = load %ptr, %ptr* %t2
	%r74 = inttoptr %word 0 to %ptr
	%r75 = load %ptr, %ptr* %t1
	%r76 = load %ptr, %ptr* %t5
	%r77 = call %ptr @"new-<variable>"(%ptr %r73, %ptr %r74, %ptr %r75, %ptr %r76)
	store %ptr %r77, %ptr* %t6
	%r79 = getelementptr %ptr, %ptr* %t6, %word 0
	%r78 = bitcast %ptr* %r79 to %ptr
	%r80 = call %ptr @"gc/push-root"(%ptr %r78)
	%r81 = load %ptr, %ptr* %t1
	store %ptr %r81, %ptr* %t7
	%r82 = inttoptr %word 0 to %ptr
	%r83 = inttoptr %word 1 to %ptr
	%r84 = inttoptr %word 1 to %ptr
	%r85 = inttoptr %word 1 to %ptr
	%r86 = load %ptr, %ptr* %t5
	%r90 = ptrtoint %ptr %r86 to %word
	%r89 = ptrtoint %ptr %r85 to %word
	%r88 = add %word %r90, %r89
	%r87 = inttoptr %word %r88 to %ptr
	%r94 = ptrtoint %ptr %r87 to %word
	%r93 = ptrtoint %ptr %r84 to %word
	%r92 = shl %word %r94, %r93
	%r91 = inttoptr %word %r92 to %ptr
	%r98 = ptrtoint %ptr %r91 to %word
	%r97 = ptrtoint %ptr %r83 to %word
	%r96 = add %word %r98, %r97
	%r95 = inttoptr %word %r96 to %ptr
	%r99 = inttoptr %word 2 to %ptr
	%r100 = load %ptr, %ptr* %t7
	%r104 = bitcast %ptr %r100 to [0 x %ptr]*
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = getelementptr [0 x %ptr], [0 x %ptr]* %r104, %word 0, %word %r103
	store %ptr %r95, %ptr* %r102
	%r101 = bitcast %ptr %r95 to %ptr
	%r105 = load %ptr, %ptr* %t3
	%r106 = load %ptr, %ptr* %t6
	%r107 = call %ptr @"k/array-append"(%ptr %r105, %ptr %r106)
	store %ptr %r107, %ptr* %t7
	%r109 = getelementptr %ptr, %ptr* %t6, %word 0
	%r108 = bitcast %ptr* %r109 to %ptr
	%r110 = call %ptr @"gc/pop-root"(%ptr %r108)
	%r111 = load %ptr, %ptr* %t7
	ret %ptr %r111
}
define %ptr @"k/env/define"(%ptr %env, %ptr %name, %ptr %value) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %env, %ptr* %t1
	store %ptr %name, %ptr* %t2
	store %ptr %value, %ptr* %t3
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = inttoptr %word 0 to %ptr
	%r4 = load %ptr, %ptr* %t1
	%r5 = load %ptr, %ptr* %t2
	%r6 = call %ptr @"k/env/ensure-variable"(%ptr %r4, %ptr %r5)
	store %ptr %r6, %ptr* %t4
	%r7 = load %ptr, %ptr* %t4
	store %ptr %r7, %ptr* %t5
	%r8 = inttoptr %word 0 to %ptr
	%r9 = load %ptr, %ptr* %t3
	%r10 = inttoptr %word 1 to %ptr
	%r11 = load %ptr, %ptr* %t5
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	store %ptr %r9, %ptr* %r13
	%r12 = bitcast %ptr %r9 to %ptr
	%r16 = load %ptr, %ptr* %t4
	ret %ptr %r16
}
define %ptr @is_blank(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	%r3 = inttoptr %word 32 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	store %ptr %r4, %ptr* %t2
	%r8 = inttoptr %word 0 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r4 to %word
	%r10 = icmp eq %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	%r14 = ptrtoint %ptr %r9 to %word
	%r13 = icmp ne %word %r14, 0
	br i1 %r13, label %L206, label %L205
L206:
	%r15 = load %ptr, %ptr* %t1
	%r16 = inttoptr %word 9 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	store %ptr %r17, %ptr* %t2
	%r21 = inttoptr %word 0 to %ptr
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r25, %r24
	%r22 = inttoptr i1 %r23 to %ptr
	%r27 = ptrtoint %ptr %r22 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L207, label %L205
L207:
	%r28 = load %ptr, %ptr* %t1
	%r29 = inttoptr %word 10 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	store %ptr %r30, %ptr* %t2
	%r34 = inttoptr %word 0 to %ptr
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = icmp eq %word %r38, %r37
	%r35 = inttoptr i1 %r36 to %ptr
	%r40 = ptrtoint %ptr %r35 to %word
	%r39 = icmp ne %word %r40, 0
	br i1 %r39, label %L208, label %L205
L208:
	%r41 = load %ptr, %ptr* %t1
	%r42 = inttoptr %word 11 to %ptr
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = icmp eq %word %r46, %r45
	%r43 = inttoptr i1 %r44 to %ptr
	store %ptr %r43, %ptr* %t2
	%r47 = inttoptr %word 0 to %ptr
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r43 to %word
	%r49 = icmp eq %word %r51, %r50
	%r48 = inttoptr i1 %r49 to %ptr
	%r53 = ptrtoint %ptr %r48 to %word
	%r52 = icmp ne %word %r53, 0
	br i1 %r52, label %L209, label %L205
L209:
	%r54 = load %ptr, %ptr* %t1
	%r55 = inttoptr %word 12 to %ptr
	%r59 = ptrtoint %ptr %r55 to %word
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = icmp eq %word %r59, %r58
	%r56 = inttoptr i1 %r57 to %ptr
	store %ptr %r56, %ptr* %t2
	%r60 = inttoptr %word 0 to %ptr
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r56 to %word
	%r62 = icmp eq %word %r64, %r63
	%r61 = inttoptr i1 %r62 to %ptr
	%r66 = ptrtoint %ptr %r61 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L210, label %L205
L210:
	%r67 = load %ptr, %ptr* %t1
	%r68 = inttoptr %word 13 to %ptr
	%r72 = ptrtoint %ptr %r68 to %word
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = icmp eq %word %r72, %r71
	%r69 = inttoptr i1 %r70 to %ptr
	store %ptr %r69, %ptr* %t2
	%r73 = inttoptr %word 0 to %ptr
	%r77 = ptrtoint %ptr %r73 to %word
	%r76 = ptrtoint %ptr %r69 to %word
	%r75 = icmp eq %word %r77, %r76
	%r74 = inttoptr i1 %r75 to %ptr
	%r79 = ptrtoint %ptr %r74 to %word
	%r78 = icmp ne %word %r79, 0
	br i1 %r78, label %L211, label %L205
L211:
	br label %L205
L205:
	%r80 = load %ptr, %ptr* %t2
	ret %ptr %r80
}
define %ptr @is_digit10(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	%r3 = inttoptr %word 48 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp sle %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	store %ptr %r4, %ptr* %t2
	%r8 = inttoptr %word 0 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r4 to %word
	%r10 = icmp eq %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	%r14 = ptrtoint %ptr %r9 to %word
	%r13 = icmp ne %word %r14, 0
	br i1 %r13, label %L212, label %L213
L213:
	%r15 = inttoptr %word 57 to %ptr
	%r16 = load %ptr, %ptr* %t1
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp sle %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	store %ptr %r17, %ptr* %t2
	%r21 = inttoptr %word 0 to %ptr
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r25, %r24
	%r22 = inttoptr i1 %r23 to %ptr
	%r27 = ptrtoint %ptr %r22 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L212, label %L214
L214:
	br label %L212
L212:
	%r28 = load %ptr, %ptr* %t2
	ret %ptr %r28
}
define %ptr @is_digit16(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = inttoptr %word 48 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp sle %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	store %ptr %r5, %ptr* %t3
	%r9 = inttoptr %word 0 to %ptr
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = ptrtoint %ptr %r5 to %word
	%r11 = icmp eq %word %r13, %r12
	%r10 = inttoptr i1 %r11 to %ptr
	%r15 = ptrtoint %ptr %r10 to %word
	%r14 = icmp ne %word %r15, 0
	br i1 %r14, label %L216, label %L217
L217:
	%r16 = inttoptr %word 57 to %ptr
	%r17 = load %ptr, %ptr* %t1
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp sle %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t3
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L216, label %L218
L218:
	br label %L216
L216:
	%r29 = load %ptr, %ptr* %t3
	store %ptr %r29, %ptr* %t2
	%r30 = inttoptr %word 0 to %ptr
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = icmp eq %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	%r36 = ptrtoint %ptr %r31 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L219, label %L215
L219:
	%r37 = inttoptr %word 1 to %ptr
	store %ptr %r37, %ptr* %t3
	%r38 = load %ptr, %ptr* %t1
	%r39 = inttoptr %word 97 to %ptr
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = icmp sle %word %r43, %r42
	%r40 = inttoptr i1 %r41 to %ptr
	store %ptr %r40, %ptr* %t3
	%r44 = inttoptr %word 0 to %ptr
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r40 to %word
	%r46 = icmp eq %word %r48, %r47
	%r45 = inttoptr i1 %r46 to %ptr
	%r50 = ptrtoint %ptr %r45 to %word
	%r49 = icmp ne %word %r50, 0
	br i1 %r49, label %L220, label %L221
L221:
	%r51 = inttoptr %word 102 to %ptr
	%r52 = load %ptr, %ptr* %t1
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = icmp sle %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	store %ptr %r53, %ptr* %t3
	%r57 = inttoptr %word 0 to %ptr
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r53 to %word
	%r59 = icmp eq %word %r61, %r60
	%r58 = inttoptr i1 %r59 to %ptr
	%r63 = ptrtoint %ptr %r58 to %word
	%r62 = icmp ne %word %r63, 0
	br i1 %r62, label %L220, label %L222
L222:
	br label %L220
L220:
	%r64 = load %ptr, %ptr* %t3
	store %ptr %r64, %ptr* %t2
	%r65 = inttoptr %word 0 to %ptr
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = ptrtoint %ptr %r64 to %word
	%r67 = icmp eq %word %r69, %r68
	%r66 = inttoptr i1 %r67 to %ptr
	%r71 = ptrtoint %ptr %r66 to %word
	%r70 = icmp ne %word %r71, 0
	br i1 %r70, label %L223, label %L215
L223:
	%r72 = inttoptr %word 1 to %ptr
	store %ptr %r72, %ptr* %t3
	%r73 = load %ptr, %ptr* %t1
	%r74 = inttoptr %word 65 to %ptr
	%r78 = ptrtoint %ptr %r74 to %word
	%r77 = ptrtoint %ptr %r73 to %word
	%r76 = icmp sle %word %r78, %r77
	%r75 = inttoptr i1 %r76 to %ptr
	store %ptr %r75, %ptr* %t3
	%r79 = inttoptr %word 0 to %ptr
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = ptrtoint %ptr %r75 to %word
	%r81 = icmp eq %word %r83, %r82
	%r80 = inttoptr i1 %r81 to %ptr
	%r85 = ptrtoint %ptr %r80 to %word
	%r84 = icmp ne %word %r85, 0
	br i1 %r84, label %L224, label %L225
L225:
	%r86 = inttoptr %word 70 to %ptr
	%r87 = load %ptr, %ptr* %t1
	%r91 = ptrtoint %ptr %r87 to %word
	%r90 = ptrtoint %ptr %r86 to %word
	%r89 = icmp sle %word %r91, %r90
	%r88 = inttoptr i1 %r89 to %ptr
	store %ptr %r88, %ptr* %t3
	%r92 = inttoptr %word 0 to %ptr
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = ptrtoint %ptr %r88 to %word
	%r94 = icmp eq %word %r96, %r95
	%r93 = inttoptr i1 %r94 to %ptr
	%r98 = ptrtoint %ptr %r93 to %word
	%r97 = icmp ne %word %r98, 0
	br i1 %r97, label %L224, label %L226
L226:
	br label %L224
L224:
	%r99 = load %ptr, %ptr* %t3
	store %ptr %r99, %ptr* %t2
	%r100 = inttoptr %word 0 to %ptr
	%r104 = ptrtoint %ptr %r100 to %word
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = icmp eq %word %r104, %r103
	%r101 = inttoptr i1 %r102 to %ptr
	%r106 = ptrtoint %ptr %r101 to %word
	%r105 = icmp ne %word %r106, 0
	br i1 %r105, label %L227, label %L215
L227:
	br label %L215
L215:
	%r107 = load %ptr, %ptr* %t2
	ret %ptr %r107
}
define %ptr @is_alpha(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = inttoptr %word 97 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp sle %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	store %ptr %r5, %ptr* %t3
	%r9 = inttoptr %word 0 to %ptr
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = ptrtoint %ptr %r5 to %word
	%r11 = icmp eq %word %r13, %r12
	%r10 = inttoptr i1 %r11 to %ptr
	%r15 = ptrtoint %ptr %r10 to %word
	%r14 = icmp ne %word %r15, 0
	br i1 %r14, label %L229, label %L230
L230:
	%r16 = inttoptr %word 122 to %ptr
	%r17 = load %ptr, %ptr* %t1
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp sle %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t3
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L229, label %L231
L231:
	br label %L229
L229:
	%r29 = load %ptr, %ptr* %t3
	store %ptr %r29, %ptr* %t2
	%r30 = inttoptr %word 0 to %ptr
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = icmp eq %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	%r36 = ptrtoint %ptr %r31 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L232, label %L228
L232:
	%r37 = inttoptr %word 1 to %ptr
	store %ptr %r37, %ptr* %t3
	%r38 = load %ptr, %ptr* %t1
	%r39 = inttoptr %word 65 to %ptr
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = icmp sle %word %r43, %r42
	%r40 = inttoptr i1 %r41 to %ptr
	store %ptr %r40, %ptr* %t3
	%r44 = inttoptr %word 0 to %ptr
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r40 to %word
	%r46 = icmp eq %word %r48, %r47
	%r45 = inttoptr i1 %r46 to %ptr
	%r50 = ptrtoint %ptr %r45 to %word
	%r49 = icmp ne %word %r50, 0
	br i1 %r49, label %L233, label %L234
L234:
	%r51 = inttoptr %word 90 to %ptr
	%r52 = load %ptr, %ptr* %t1
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = icmp sle %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	store %ptr %r53, %ptr* %t3
	%r57 = inttoptr %word 0 to %ptr
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r53 to %word
	%r59 = icmp eq %word %r61, %r60
	%r58 = inttoptr i1 %r59 to %ptr
	%r63 = ptrtoint %ptr %r58 to %word
	%r62 = icmp ne %word %r63, 0
	br i1 %r62, label %L233, label %L235
L235:
	br label %L233
L233:
	%r64 = load %ptr, %ptr* %t3
	store %ptr %r64, %ptr* %t2
	%r65 = inttoptr %word 0 to %ptr
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = ptrtoint %ptr %r64 to %word
	%r67 = icmp eq %word %r69, %r68
	%r66 = inttoptr i1 %r67 to %ptr
	%r71 = ptrtoint %ptr %r66 to %word
	%r70 = icmp ne %word %r71, 0
	br i1 %r70, label %L236, label %L228
L236:
	br label %L228
L228:
	%r72 = load %ptr, %ptr* %t2
	ret %ptr %r72
}
define %ptr @is_letter(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	%r3 = inttoptr %word 33 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	store %ptr %r4, %ptr* %t2
	%r8 = inttoptr %word 0 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r4 to %word
	%r10 = icmp eq %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	%r14 = ptrtoint %ptr %r9 to %word
	%r13 = icmp ne %word %r14, 0
	br i1 %r13, label %L238, label %L237
L238:
	%r15 = inttoptr %word 1 to %ptr
	store %ptr %r15, %ptr* %t3
	%r16 = load %ptr, %ptr* %t1
	%r17 = inttoptr %word 35 to %ptr
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp sle %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t3
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L239, label %L240
L240:
	%r29 = inttoptr %word 38 to %ptr
	%r30 = load %ptr, %ptr* %t1
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = icmp sle %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	store %ptr %r31, %ptr* %t3
	%r35 = inttoptr %word 0 to %ptr
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = ptrtoint %ptr %r31 to %word
	%r37 = icmp eq %word %r39, %r38
	%r36 = inttoptr i1 %r37 to %ptr
	%r41 = ptrtoint %ptr %r36 to %word
	%r40 = icmp ne %word %r41, 0
	br i1 %r40, label %L239, label %L241
L241:
	br label %L239
L239:
	%r42 = load %ptr, %ptr* %t3
	store %ptr %r42, %ptr* %t2
	%r43 = inttoptr %word 0 to %ptr
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = icmp eq %word %r47, %r46
	%r44 = inttoptr i1 %r45 to %ptr
	%r49 = ptrtoint %ptr %r44 to %word
	%r48 = icmp ne %word %r49, 0
	br i1 %r48, label %L242, label %L237
L242:
	%r50 = inttoptr %word 1 to %ptr
	store %ptr %r50, %ptr* %t3
	%r51 = load %ptr, %ptr* %t1
	%r52 = inttoptr %word 42 to %ptr
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = icmp sle %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	store %ptr %r53, %ptr* %t3
	%r57 = inttoptr %word 0 to %ptr
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r53 to %word
	%r59 = icmp eq %word %r61, %r60
	%r58 = inttoptr i1 %r59 to %ptr
	%r63 = ptrtoint %ptr %r58 to %word
	%r62 = icmp ne %word %r63, 0
	br i1 %r62, label %L243, label %L244
L244:
	%r64 = inttoptr %word 47 to %ptr
	%r65 = load %ptr, %ptr* %t1
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = ptrtoint %ptr %r64 to %word
	%r67 = icmp sle %word %r69, %r68
	%r66 = inttoptr i1 %r67 to %ptr
	store %ptr %r66, %ptr* %t3
	%r70 = inttoptr %word 0 to %ptr
	%r74 = ptrtoint %ptr %r70 to %word
	%r73 = ptrtoint %ptr %r66 to %word
	%r72 = icmp eq %word %r74, %r73
	%r71 = inttoptr i1 %r72 to %ptr
	%r76 = ptrtoint %ptr %r71 to %word
	%r75 = icmp ne %word %r76, 0
	br i1 %r75, label %L243, label %L245
L245:
	br label %L243
L243:
	%r77 = load %ptr, %ptr* %t3
	store %ptr %r77, %ptr* %t2
	%r78 = inttoptr %word 0 to %ptr
	%r82 = ptrtoint %ptr %r78 to %word
	%r81 = ptrtoint %ptr %r77 to %word
	%r80 = icmp eq %word %r82, %r81
	%r79 = inttoptr i1 %r80 to %ptr
	%r84 = ptrtoint %ptr %r79 to %word
	%r83 = icmp ne %word %r84, 0
	br i1 %r83, label %L246, label %L237
L246:
	%r85 = load %ptr, %ptr* %t1
	%r86 = inttoptr %word 58 to %ptr
	%r90 = ptrtoint %ptr %r86 to %word
	%r89 = ptrtoint %ptr %r85 to %word
	%r88 = icmp eq %word %r90, %r89
	%r87 = inttoptr i1 %r88 to %ptr
	store %ptr %r87, %ptr* %t2
	%r91 = inttoptr %word 0 to %ptr
	%r95 = ptrtoint %ptr %r91 to %word
	%r94 = ptrtoint %ptr %r87 to %word
	%r93 = icmp eq %word %r95, %r94
	%r92 = inttoptr i1 %r93 to %ptr
	%r97 = ptrtoint %ptr %r92 to %word
	%r96 = icmp ne %word %r97, 0
	br i1 %r96, label %L247, label %L237
L247:
	%r98 = inttoptr %word 1 to %ptr
	store %ptr %r98, %ptr* %t3
	%r99 = load %ptr, %ptr* %t1
	%r100 = inttoptr %word 60 to %ptr
	%r104 = ptrtoint %ptr %r100 to %word
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = icmp sle %word %r104, %r103
	%r101 = inttoptr i1 %r102 to %ptr
	store %ptr %r101, %ptr* %t3
	%r105 = inttoptr %word 0 to %ptr
	%r109 = ptrtoint %ptr %r105 to %word
	%r108 = ptrtoint %ptr %r101 to %word
	%r107 = icmp eq %word %r109, %r108
	%r106 = inttoptr i1 %r107 to %ptr
	%r111 = ptrtoint %ptr %r106 to %word
	%r110 = icmp ne %word %r111, 0
	br i1 %r110, label %L248, label %L249
L249:
	%r112 = inttoptr %word 90 to %ptr
	%r113 = load %ptr, %ptr* %t1
	%r117 = ptrtoint %ptr %r113 to %word
	%r116 = ptrtoint %ptr %r112 to %word
	%r115 = icmp sle %word %r117, %r116
	%r114 = inttoptr i1 %r115 to %ptr
	store %ptr %r114, %ptr* %t3
	%r118 = inttoptr %word 0 to %ptr
	%r122 = ptrtoint %ptr %r118 to %word
	%r121 = ptrtoint %ptr %r114 to %word
	%r120 = icmp eq %word %r122, %r121
	%r119 = inttoptr i1 %r120 to %ptr
	%r124 = ptrtoint %ptr %r119 to %word
	%r123 = icmp ne %word %r124, 0
	br i1 %r123, label %L248, label %L250
L250:
	br label %L248
L248:
	%r125 = load %ptr, %ptr* %t3
	store %ptr %r125, %ptr* %t2
	%r126 = inttoptr %word 0 to %ptr
	%r130 = ptrtoint %ptr %r126 to %word
	%r129 = ptrtoint %ptr %r125 to %word
	%r128 = icmp eq %word %r130, %r129
	%r127 = inttoptr i1 %r128 to %ptr
	%r132 = ptrtoint %ptr %r127 to %word
	%r131 = icmp ne %word %r132, 0
	br i1 %r131, label %L251, label %L237
L251:
	%r133 = load %ptr, %ptr* %t1
	%r134 = inttoptr %word 92 to %ptr
	%r138 = ptrtoint %ptr %r134 to %word
	%r137 = ptrtoint %ptr %r133 to %word
	%r136 = icmp eq %word %r138, %r137
	%r135 = inttoptr i1 %r136 to %ptr
	store %ptr %r135, %ptr* %t2
	%r139 = inttoptr %word 0 to %ptr
	%r143 = ptrtoint %ptr %r139 to %word
	%r142 = ptrtoint %ptr %r135 to %word
	%r141 = icmp eq %word %r143, %r142
	%r140 = inttoptr i1 %r141 to %ptr
	%r145 = ptrtoint %ptr %r140 to %word
	%r144 = icmp ne %word %r145, 0
	br i1 %r144, label %L252, label %L237
L252:
	%r146 = load %ptr, %ptr* %t1
	%r147 = inttoptr %word 94 to %ptr
	%r151 = ptrtoint %ptr %r147 to %word
	%r150 = ptrtoint %ptr %r146 to %word
	%r149 = icmp eq %word %r151, %r150
	%r148 = inttoptr i1 %r149 to %ptr
	store %ptr %r148, %ptr* %t2
	%r152 = inttoptr %word 0 to %ptr
	%r156 = ptrtoint %ptr %r152 to %word
	%r155 = ptrtoint %ptr %r148 to %word
	%r154 = icmp eq %word %r156, %r155
	%r153 = inttoptr i1 %r154 to %ptr
	%r158 = ptrtoint %ptr %r153 to %word
	%r157 = icmp ne %word %r158, 0
	br i1 %r157, label %L253, label %L237
L253:
	%r159 = load %ptr, %ptr* %t1
	%r160 = inttoptr %word 95 to %ptr
	%r164 = ptrtoint %ptr %r160 to %word
	%r163 = ptrtoint %ptr %r159 to %word
	%r162 = icmp eq %word %r164, %r163
	%r161 = inttoptr i1 %r162 to %ptr
	store %ptr %r161, %ptr* %t2
	%r165 = inttoptr %word 0 to %ptr
	%r169 = ptrtoint %ptr %r165 to %word
	%r168 = ptrtoint %ptr %r161 to %word
	%r167 = icmp eq %word %r169, %r168
	%r166 = inttoptr i1 %r167 to %ptr
	%r171 = ptrtoint %ptr %r166 to %word
	%r170 = icmp ne %word %r171, 0
	br i1 %r170, label %L254, label %L237
L254:
	%r172 = inttoptr %word 1 to %ptr
	store %ptr %r172, %ptr* %t3
	%r173 = load %ptr, %ptr* %t1
	%r174 = inttoptr %word 97 to %ptr
	%r178 = ptrtoint %ptr %r174 to %word
	%r177 = ptrtoint %ptr %r173 to %word
	%r176 = icmp sle %word %r178, %r177
	%r175 = inttoptr i1 %r176 to %ptr
	store %ptr %r175, %ptr* %t3
	%r179 = inttoptr %word 0 to %ptr
	%r183 = ptrtoint %ptr %r179 to %word
	%r182 = ptrtoint %ptr %r175 to %word
	%r181 = icmp eq %word %r183, %r182
	%r180 = inttoptr i1 %r181 to %ptr
	%r185 = ptrtoint %ptr %r180 to %word
	%r184 = icmp ne %word %r185, 0
	br i1 %r184, label %L255, label %L256
L256:
	%r186 = inttoptr %word 122 to %ptr
	%r187 = load %ptr, %ptr* %t1
	%r191 = ptrtoint %ptr %r187 to %word
	%r190 = ptrtoint %ptr %r186 to %word
	%r189 = icmp sle %word %r191, %r190
	%r188 = inttoptr i1 %r189 to %ptr
	store %ptr %r188, %ptr* %t3
	%r192 = inttoptr %word 0 to %ptr
	%r196 = ptrtoint %ptr %r192 to %word
	%r195 = ptrtoint %ptr %r188 to %word
	%r194 = icmp eq %word %r196, %r195
	%r193 = inttoptr i1 %r194 to %ptr
	%r198 = ptrtoint %ptr %r193 to %word
	%r197 = icmp ne %word %r198, 0
	br i1 %r197, label %L255, label %L257
L257:
	br label %L255
L255:
	%r199 = load %ptr, %ptr* %t3
	store %ptr %r199, %ptr* %t2
	%r200 = inttoptr %word 0 to %ptr
	%r204 = ptrtoint %ptr %r200 to %word
	%r203 = ptrtoint %ptr %r199 to %word
	%r202 = icmp eq %word %r204, %r203
	%r201 = inttoptr i1 %r202 to %ptr
	%r206 = ptrtoint %ptr %r201 to %word
	%r205 = icmp ne %word %r206, 0
	br i1 %r205, label %L258, label %L237
L258:
	%r207 = load %ptr, %ptr* %t1
	%r208 = inttoptr %word 124 to %ptr
	%r212 = ptrtoint %ptr %r208 to %word
	%r211 = ptrtoint %ptr %r207 to %word
	%r210 = icmp eq %word %r212, %r211
	%r209 = inttoptr i1 %r210 to %ptr
	store %ptr %r209, %ptr* %t2
	%r213 = inttoptr %word 0 to %ptr
	%r217 = ptrtoint %ptr %r213 to %word
	%r216 = ptrtoint %ptr %r209 to %word
	%r215 = icmp eq %word %r217, %r216
	%r214 = inttoptr i1 %r215 to %ptr
	%r219 = ptrtoint %ptr %r214 to %word
	%r218 = icmp ne %word %r219, 0
	br i1 %r218, label %L259, label %L237
L259:
	%r220 = load %ptr, %ptr* %t1
	%r221 = inttoptr %word 126 to %ptr
	%r225 = ptrtoint %ptr %r221 to %word
	%r224 = ptrtoint %ptr %r220 to %word
	%r223 = icmp eq %word %r225, %r224
	%r222 = inttoptr i1 %r223 to %ptr
	store %ptr %r222, %ptr* %t2
	%r226 = inttoptr %word 0 to %ptr
	%r230 = ptrtoint %ptr %r226 to %word
	%r229 = ptrtoint %ptr %r222 to %word
	%r228 = icmp eq %word %r230, %r229
	%r227 = inttoptr i1 %r228 to %ptr
	%r232 = ptrtoint %ptr %r227 to %word
	%r231 = icmp ne %word %r232, 0
	br i1 %r231, label %L260, label %L237
L260:
	br label %L237
L237:
	%r233 = load %ptr, %ptr* %t2
	ret %ptr %r233
}
define %ptr @new_buffer() {
	%t1 = alloca %ptr
	%r1 = inttoptr %word 12 to %ptr
	%ffi-cast2 = ptrtoint %ptr %r1 to i32
	%r3 = call %ptr @malloc(i32 %ffi-cast2)
	store %ptr %r3, %ptr* %t1
	%r4 = inttoptr %word 32 to %ptr
	%ffi-cast5 = ptrtoint %ptr %r4 to i32
	%r6 = call %ptr @malloc(i32 %ffi-cast5)
	%r7 = inttoptr %word 0 to %ptr
	%r8 = load %ptr, %ptr* %t1
	%r12 = bitcast %ptr %r8 to [0 x %ptr]*
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = getelementptr [0 x %ptr], [0 x %ptr]* %r12, %word 0, %word %r11
	store %ptr %r6, %ptr* %r10
	%r9 = bitcast %ptr %r6 to %ptr
	%r13 = inttoptr %word 32 to %ptr
	%r14 = inttoptr %word 1 to %ptr
	%r15 = load %ptr, %ptr* %t1
	%r19 = bitcast %ptr %r15 to [0 x %ptr]*
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = getelementptr [0 x %ptr], [0 x %ptr]* %r19, %word 0, %word %r18
	store %ptr %r13, %ptr* %r17
	%r16 = bitcast %ptr %r13 to %ptr
	%r20 = inttoptr %word 0 to %ptr
	%r21 = inttoptr %word 2 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	store %ptr %r20, %ptr* %r24
	%r23 = bitcast %ptr %r20 to %ptr
	%r27 = load %ptr, %ptr* %t1
	ret %ptr %r27
}
define %ptr @buffer_delete(%ptr %buf) {
	%t1 = alloca %ptr
	store %ptr %buf, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r6 = bitcast %ptr %r2 to [0 x %ptr]*
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = getelementptr [0 x %ptr], [0 x %ptr]* %r6, %word 0, %word %r5
	%r3 = load %ptr, %ptr* %r4
	call void @free(%ptr %r3)
	%r8 = inttoptr %word 0 to %ptr
	%r9 = load %ptr, %ptr* %t1
	call void @free(%ptr %r9)
	%r11 = inttoptr %word 0 to %ptr
	ret %ptr %r11
}
define %ptr @buffer_grow(%ptr %buf) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %buf, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r6 = bitcast %ptr %r2 to [0 x %ptr]*
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = getelementptr [0 x %ptr], [0 x %ptr]* %r6, %word 0, %word %r5
	%r3 = load %ptr, %ptr* %r4
	store %ptr %r3, %ptr* %t2
	%r7 = load %ptr, %ptr* %t2
	%r8 = inttoptr %word 2 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = mul %word %r12, %r11
	%r9 = inttoptr %word %r10 to %ptr
	%ffi-cast13 = ptrtoint %ptr %r9 to i32
	%r14 = call %ptr @malloc(i32 %ffi-cast13)
	store %ptr %r14, %ptr* %t3
	%r15 = load %ptr, %ptr* %t3
	%r16 = inttoptr %word 0 to %ptr
	%r17 = load %ptr, %ptr* %t1
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	%r18 = load %ptr, %ptr* %r19
	%r22 = load %ptr, %ptr* %t2
	%ffi-cast23 = ptrtoint %ptr %r22 to i32
	%r24 = call %ptr @memcpy(%ptr %r15, %ptr %r18, i32 %ffi-cast23)
	%r25 = inttoptr %word 0 to %ptr
	%r26 = load %ptr, %ptr* %t1
	%r30 = bitcast %ptr %r26 to [0 x %ptr]*
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = getelementptr [0 x %ptr], [0 x %ptr]* %r30, %word 0, %word %r29
	%r27 = load %ptr, %ptr* %r28
	call void @free(%ptr %r27)
	%r32 = inttoptr %word 0 to %ptr
	%r33 = load %ptr, %ptr* %t3
	%r34 = inttoptr %word 0 to %ptr
	%r35 = load %ptr, %ptr* %t1
	%r39 = bitcast %ptr %r35 to [0 x %ptr]*
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = getelementptr [0 x %ptr], [0 x %ptr]* %r39, %word 0, %word %r38
	store %ptr %r33, %ptr* %r37
	%r36 = bitcast %ptr %r33 to %ptr
	%r40 = load %ptr, %ptr* %t2
	%r41 = inttoptr %word 2 to %ptr
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = mul %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	%r46 = inttoptr %word 1 to %ptr
	%r47 = load %ptr, %ptr* %t1
	%r51 = bitcast %ptr %r47 to [0 x %ptr]*
	%r50 = ptrtoint %ptr %r46 to %word
	%r49 = getelementptr [0 x %ptr], [0 x %ptr]* %r51, %word 0, %word %r50
	store %ptr %r42, %ptr* %r49
	%r48 = bitcast %ptr %r42 to %ptr
	ret %ptr %r48
}
define %ptr @buffer_append(%ptr %buf, %ptr %c) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %buf, %ptr* %t1
	store %ptr %c, %ptr* %t2
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t3
	%r2 = inttoptr %word 1 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	%r8 = inttoptr %word 2 to %ptr
	%r9 = load %ptr, %ptr* %t1
	%r13 = bitcast %ptr %r9 to [0 x %ptr]*
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = getelementptr [0 x %ptr], [0 x %ptr]* %r13, %word 0, %word %r12
	%r10 = load %ptr, %ptr* %r11
	%r17 = ptrtoint %ptr %r10 to %word
	%r16 = ptrtoint %ptr %r4 to %word
	%r15 = icmp eq %word %r17, %r16
	%r14 = inttoptr i1 %r15 to %ptr
	store %ptr %r14, %ptr* %t3
	%r18 = inttoptr %word 0 to %ptr
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = ptrtoint %ptr %r14 to %word
	%r20 = icmp eq %word %r22, %r21
	%r19 = inttoptr i1 %r20 to %ptr
	%r24 = ptrtoint %ptr %r19 to %word
	%r23 = icmp ne %word %r24, 0
	br i1 %r23, label %L261, label %L262
L262:
	%r25 = load %ptr, %ptr* %t1
	%r26 = call %ptr @buffer_grow(%ptr %r25)
	store %ptr %r26, %ptr* %t3
	%r27 = inttoptr %word 0 to %ptr
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = icmp eq %word %r31, %r30
	%r28 = inttoptr i1 %r29 to %ptr
	%r33 = ptrtoint %ptr %r28 to %word
	%r32 = icmp ne %word %r33, 0
	br i1 %r32, label %L261, label %L263
L263:
	br label %L261
L261:
	%r34 = load %ptr, %ptr* %t3
	%r35 = inttoptr %word 2 to %ptr
	%r36 = load %ptr, %ptr* %t1
	%r40 = bitcast %ptr %r36 to [0 x %ptr]*
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = getelementptr [0 x %ptr], [0 x %ptr]* %r40, %word 0, %word %r39
	%r37 = load %ptr, %ptr* %r38
	store %ptr %r37, %ptr* %t3
	%r41 = load %ptr, %ptr* %t2
	%r42 = load %ptr, %ptr* %t3
	%r43 = inttoptr %word 0 to %ptr
	%r44 = load %ptr, %ptr* %t1
	%r48 = bitcast %ptr %r44 to [0 x %ptr]*
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = getelementptr [0 x %ptr], [0 x %ptr]* %r48, %word 0, %word %r47
	%r45 = load %ptr, %ptr* %r46
	%r54 = bitcast %ptr %r45 to [0 x i8]*
	%r53 = ptrtoint %ptr %r42 to %word
	%r52 = getelementptr [0 x i8], [0 x i8]* %r54, %word 0, %word %r53
	%r51 = ptrtoint %ptr %r41 to i8
	store i8 %r51, i8* %r52
	%r50 = zext i8 %r51 to %word
	%r49 = inttoptr %word %r50 to %ptr
	%r55 = load %ptr, %ptr* %t3
	%r56 = inttoptr %word 1 to %ptr
	%r60 = ptrtoint %ptr %r56 to %word
	%r59 = ptrtoint %ptr %r55 to %word
	%r58 = add %word %r60, %r59
	%r57 = inttoptr %word %r58 to %ptr
	%r61 = inttoptr %word 2 to %ptr
	%r62 = load %ptr, %ptr* %t1
	%r66 = bitcast %ptr %r62 to [0 x %ptr]*
	%r65 = ptrtoint %ptr %r61 to %word
	%r64 = getelementptr [0 x %ptr], [0 x %ptr]* %r66, %word 0, %word %r65
	store %ptr %r57, %ptr* %r64
	%r63 = bitcast %ptr %r57 to %ptr
	ret %ptr %r63
}
define %ptr @buffer_append_all(%ptr %buf, %ptr %s) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %buf, %ptr* %t1
	store %ptr %s, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t3
	%r2 = inttoptr %word 0 to %ptr
	store %ptr %r2, %ptr* %t4
	br label %L265
L264:
	%r3 = load %ptr, %ptr* %t1
	%r4 = load %ptr, %ptr* %t4
	%r5 = call %ptr @buffer_append(%ptr %r3, %ptr %r4)
	%r6 = load %ptr, %ptr* %t3
	%r7 = inttoptr %word 1 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = add %word %r11, %r10
	%r8 = inttoptr %word %r9 to %ptr
	store %ptr %r8, %ptr* %t3
	br label %L265
L265:
	%r12 = load %ptr, %ptr* %t3
	%r13 = load %ptr, %ptr* %t2
	%r18 = bitcast %ptr %r13 to [0 x i8]*
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = getelementptr [0 x i8], [0 x i8]* %r18, %word 0, %word %r17
	%r15 = load i8, i8* %r16
	%r14 = inttoptr i8 %r15 to %ptr
	store %ptr %r14, %ptr* %t4
	%r20 = ptrtoint %ptr %r14 to %word
	%r19 = icmp ne %word %r20, 0
	br i1 %r19, label %L264, label %L266
L266:
	ret %ptr %r14
}
define %ptr @buffer_contents(%ptr %buf) {
	%t1 = alloca %ptr
	store %ptr %buf, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = inttoptr %word 0 to %ptr
	%r3 = call %ptr @buffer_append(%ptr %r1, %ptr %r2)
	%r4 = inttoptr %word 1 to %ptr
	%r5 = inttoptr %word 2 to %ptr
	%r6 = load %ptr, %ptr* %t1
	%r10 = bitcast %ptr %r6 to [0 x %ptr]*
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = getelementptr [0 x %ptr], [0 x %ptr]* %r10, %word 0, %word %r9
	%r7 = load %ptr, %ptr* %r8
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = ptrtoint %ptr %r4 to %word
	%r12 = sub %word %r14, %r13
	%r11 = inttoptr %word %r12 to %ptr
	%r15 = inttoptr %word 2 to %ptr
	%r16 = load %ptr, %ptr* %t1
	%r20 = bitcast %ptr %r16 to [0 x %ptr]*
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = getelementptr [0 x %ptr], [0 x %ptr]* %r20, %word 0, %word %r19
	store %ptr %r11, %ptr* %r18
	%r17 = bitcast %ptr %r11 to %ptr
	%r21 = inttoptr %word 0 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	ret %ptr %r23
}
@str274 = private unnamed_addr constant [64 x i8] c"intern: '%s' is found, but it's not a module while interning %s\00"
define %ptr @"intern*"(%ptr %cstr, %ptr %module) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t3 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	store %ptr %cstr, %ptr* %t1
	store %ptr %module, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call i32 @strlen(%ptr %r2)
	%r4 = inttoptr %word %r3 to %ptr
	store %ptr %r4, %ptr* %t3
	%r5 = inttoptr %word 0 to %ptr
	store %ptr %r5, %ptr* %t4
	br label %L268
L267:
	%r6 = inttoptr %word 1 to %ptr
	store %ptr %r6, %ptr* %t5
	%r7 = load %ptr, %ptr* %t4
	%r8 = load %ptr, %ptr* %t1
	%r13 = bitcast %ptr %r8 to [0 x i8]*
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = getelementptr [0 x i8], [0 x i8]* %r13, %word 0, %word %r12
	%r10 = load i8, i8* %r11
	%r9 = inttoptr i8 %r10 to %ptr
	%r14 = inttoptr %word 58 to %ptr
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = ptrtoint %ptr %r9 to %word
	%r16 = icmp eq %word %r18, %r17
	%r15 = inttoptr i1 %r16 to %ptr
	store %ptr %r15, %ptr* %t5
	%r19 = inttoptr %word 0 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r15 to %word
	%r21 = icmp eq %word %r23, %r22
	%r20 = inttoptr i1 %r21 to %ptr
	%r25 = ptrtoint %ptr %r20 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L270, label %L271
L271:
	%r26 = load %ptr, %ptr* %t4
	%r27 = inttoptr %word 1 to %ptr
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = add %word %r31, %r30
	%r28 = inttoptr %word %r29 to %ptr
	%ffi-cast32 = ptrtoint %ptr %r28 to i32
	%r33 = call %ptr @malloc(i32 %ffi-cast32)
	store %ptr %r33, %ptr* %t6
	%r34 = load %ptr, %ptr* %t6
	%r35 = load %ptr, %ptr* %t1
	%r36 = load %ptr, %ptr* %t4
	%ffi-cast37 = ptrtoint %ptr %r36 to i32
	%r38 = call %ptr @memcpy(%ptr %r34, %ptr %r35, i32 %ffi-cast37)
	%r39 = inttoptr %word 0 to %ptr
	%r40 = load %ptr, %ptr* %t4
	%r41 = load %ptr, %ptr* %t6
	%r47 = bitcast %ptr %r41 to [0 x i8]*
	%r46 = ptrtoint %ptr %r40 to %word
	%r45 = getelementptr [0 x i8], [0 x i8]* %r47, %word 0, %word %r46
	%r44 = ptrtoint %ptr %r39 to i8
	store i8 %r44, i8* %r45
	%r43 = zext i8 %r44 to %word
	%r42 = inttoptr %word %r43 to %ptr
	%r48 = load %ptr, %ptr* %t2
	store %ptr %r48, %ptr* %t7
	%r49 = inttoptr %word 0 to %ptr
	%r50 = inttoptr %word 1 to %ptr
	%r51 = load %ptr, %ptr* %t7
	%r55 = bitcast %ptr %r51 to [0 x %ptr]*
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = getelementptr [0 x %ptr], [0 x %ptr]* %r55, %word 0, %word %r54
	%r52 = load %ptr, %ptr* %r53
	store %ptr %r52, %ptr* %t7
	%r56 = inttoptr %word 0 to %ptr
	%r57 = inttoptr %word 1 to %ptr
	%r58 = load %ptr, %ptr* %t7
	%r62 = bitcast %ptr %r58 to [0 x %ptr]*
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = getelementptr [0 x %ptr], [0 x %ptr]* %r62, %word 0, %word %r61
	%r59 = load %ptr, %ptr* %r60
	%r63 = load %ptr, %ptr* %t6
	%r64 = load %ptr, %ptr* %t2
	%r65 = call %ptr @"intern*"(%ptr %r63, %ptr %r64)
	%r66 = call %ptr @"k/env/variable-value"(%ptr %r59, %ptr %r65)
	store %ptr %r66, %ptr* %t7
	%r67 = inttoptr %word 0 to %ptr
	store %ptr %r67, %ptr* %t8
	%r68 = load %ptr, %ptr* %t7
	%r69 = call %ptr @"get/type"(%ptr %r68)
	%r70 = inttoptr %word 15 to %ptr
	%r74 = ptrtoint %ptr %r70 to %word
	%r73 = ptrtoint %ptr %r69 to %word
	%r72 = icmp eq %word %r74, %r73
	%r71 = inttoptr i1 %r72 to %ptr
	store %ptr %r71, %ptr* %t8
	%r75 = inttoptr %word 0 to %ptr
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = ptrtoint %ptr %r71 to %word
	%r77 = icmp eq %word %r79, %r78
	%r76 = inttoptr i1 %r77 to %ptr
	%r81 = ptrtoint %ptr %r76 to %word
	%r80 = icmp ne %word %r81, 0
	br i1 %r80, label %L273, label %L272
L273:
	%r82 = getelementptr [64 x i8], [64 x i8]* @str274, %word 0, %word 0
	%r84 = load %ptr, %ptr* %t6
	%r85 = load %ptr, %ptr* %t1
	%r86 = call %ptr @fatal2(%ptr %r82, %ptr %r84, %ptr %r85)
	store %ptr %r86, %ptr* %t8
	%r87 = inttoptr %word 0 to %ptr
	%r91 = ptrtoint %ptr %r87 to %word
	%r90 = ptrtoint %ptr %r86 to %word
	%r89 = icmp eq %word %r91, %r90
	%r88 = inttoptr i1 %r89 to %ptr
	%r93 = ptrtoint %ptr %r88 to %word
	%r92 = icmp ne %word %r93, 0
	br i1 %r92, label %L275, label %L272
L275:
	br label %L272
L272:
	%r94 = load %ptr, %ptr* %t8
	%r95 = load %ptr, %ptr* %t6
	call void @free(%ptr %r95)
	%r97 = inttoptr %word 0 to %ptr
	%r98 = load %ptr, %ptr* %t4
	%r99 = load %ptr, %ptr* %t1
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = ptrtoint %ptr %r98 to %word
	%r101 = add %word %r103, %r102
	%r100 = inttoptr %word %r101 to %ptr
	%r104 = inttoptr %word 1 to %ptr
	%r108 = ptrtoint %ptr %r104 to %word
	%r107 = ptrtoint %ptr %r100 to %word
	%r106 = add %word %r108, %r107
	%r105 = inttoptr %word %r106 to %ptr
	%r109 = load %ptr, %ptr* %t7
	%r110 = call %ptr @"intern*"(%ptr %r105, %ptr %r109)
	ret %ptr %r110
	store %ptr %r110, %ptr* %t5
	%r112 = inttoptr %word 0 to %ptr
	%r116 = ptrtoint %ptr %r112 to %word
	%r115 = ptrtoint %ptr %r110 to %word
	%r114 = icmp eq %word %r116, %r115
	%r113 = inttoptr i1 %r114 to %ptr
	%r118 = ptrtoint %ptr %r113 to %word
	%r117 = icmp ne %word %r118, 0
	br i1 %r117, label %L270, label %L276
L276:
	br label %L270
L270:
	%r119 = load %ptr, %ptr* %t5
	%r120 = load %ptr, %ptr* %t4
	%r121 = inttoptr %word 1 to %ptr
	%r125 = ptrtoint %ptr %r121 to %word
	%r124 = ptrtoint %ptr %r120 to %word
	%r123 = add %word %r125, %r124
	%r122 = inttoptr %word %r123 to %ptr
	store %ptr %r122, %ptr* %t4
	br label %L268
L268:
	%r126 = load %ptr, %ptr* %t3
	%r127 = load %ptr, %ptr* %t4
	%r131 = ptrtoint %ptr %r127 to %word
	%r130 = ptrtoint %ptr %r126 to %word
	%r129 = icmp slt %word %r131, %r130
	%r128 = inttoptr i1 %r129 to %ptr
	%r133 = ptrtoint %ptr %r128 to %word
	%r132 = icmp ne %word %r133, 0
	br i1 %r132, label %L267, label %L269
L269:
	%r134 = load %ptr, %ptr* %t2
	store %ptr %r134, %ptr* %t4
	%r135 = inttoptr %word 0 to %ptr
	%r136 = inttoptr %word 0 to %ptr
	%r137 = load %ptr, %ptr* %t4
	%r141 = bitcast %ptr %r137 to [0 x %ptr]*
	%r140 = ptrtoint %ptr %r136 to %word
	%r139 = getelementptr [0 x %ptr], [0 x %ptr]* %r141, %word 0, %word %r140
	%r138 = load %ptr, %ptr* %r139
	store %ptr %r138, %ptr* %t4
	%r142 = inttoptr %word 0 to %ptr
	store %ptr %r142, %ptr* %t3
	%r143 = inttoptr %word 1 to %ptr
	%r144 = load %ptr, %ptr* %t4
	%r145 = call %ptr @"k/array-length"(%ptr %r144)
	%r149 = ptrtoint %ptr %r145 to %word
	%r148 = ptrtoint %ptr %r143 to %word
	%r147 = sub %word %r149, %r148
	%r146 = inttoptr %word %r147 to %ptr
	store %ptr %r146, %ptr* %t5
	br label %L278
L277:
	%r150 = inttoptr %word 2 to %ptr
	%r151 = load %ptr, %ptr* %t5
	%r152 = load %ptr, %ptr* %t3
	%r156 = ptrtoint %ptr %r152 to %word
	%r155 = ptrtoint %ptr %r151 to %word
	%r154 = add %word %r156, %r155
	%r153 = inttoptr %word %r154 to %ptr
	%r160 = ptrtoint %ptr %r153 to %word
	%r159 = ptrtoint %ptr %r150 to %word
	%r158 = sdiv %word %r160, %r159
	%r157 = inttoptr %word %r158 to %ptr
	store %ptr %r157, %ptr* %t6
	%r161 = load %ptr, %ptr* %t4
	%r162 = load %ptr, %ptr* %t6
	%r163 = call %ptr @"k/array-at"(%ptr %r161, %ptr %r162)
	store %ptr %r163, %ptr* %t7
	%r164 = load %ptr, %ptr* %t1
	%r165 = load %ptr, %ptr* %t7
	store %ptr %r165, %ptr* %t8
	%r166 = inttoptr %word 0 to %ptr
	%r167 = inttoptr %word 0 to %ptr
	%r168 = load %ptr, %ptr* %t8
	%r172 = bitcast %ptr %r168 to [0 x %ptr]*
	%r171 = ptrtoint %ptr %r167 to %word
	%r170 = getelementptr [0 x %ptr], [0 x %ptr]* %r172, %word 0, %word %r171
	%r169 = load %ptr, %ptr* %r170
	%r173 = call i32 @strcmp(%ptr %r164, %ptr %r169)
	%r174 = inttoptr %word %r173 to %ptr
	store %ptr %r174, %ptr* %t8
	%r175 = inttoptr %word 0 to %ptr
	%r176 = load %ptr, %ptr* %t8
	%r180 = ptrtoint %ptr %r176 to %word
	%r179 = ptrtoint %ptr %r175 to %word
	%r178 = icmp slt %word %r180, %r179
	%r177 = inttoptr i1 %r178 to %ptr
	%r182 = ptrtoint %ptr %r177 to %word
	%r181 = icmp ne %word %r182, 0
	br i1 %r181, label %L280, label %L281
L280:
	%r183 = inttoptr %word 1 to %ptr
	%r184 = load %ptr, %ptr* %t6
	%r188 = ptrtoint %ptr %r184 to %word
	%r187 = ptrtoint %ptr %r183 to %word
	%r186 = sub %word %r188, %r187
	%r185 = inttoptr %word %r186 to %ptr
	store %ptr %r185, %ptr* %t5
	store %ptr %r185, %ptr* %t9
	br label %L282
L281:
	%r189 = inttoptr %word 0 to %ptr
	%r190 = load %ptr, %ptr* %t8
	%r194 = ptrtoint %ptr %r190 to %word
	%r193 = ptrtoint %ptr %r189 to %word
	%r192 = icmp sgt %word %r194, %r193
	%r191 = inttoptr i1 %r192 to %ptr
	%r196 = ptrtoint %ptr %r191 to %word
	%r195 = icmp ne %word %r196, 0
	br i1 %r195, label %L283, label %L284
L283:
	%r197 = inttoptr %word 1 to %ptr
	%r198 = load %ptr, %ptr* %t6
	%r202 = ptrtoint %ptr %r198 to %word
	%r201 = ptrtoint %ptr %r197 to %word
	%r200 = add %word %r202, %r201
	%r199 = inttoptr %word %r200 to %ptr
	store %ptr %r199, %ptr* %t3
	store %ptr %r199, %ptr* %t10
	br label %L285
L284:
	%r203 = load %ptr, %ptr* %t7
	ret %ptr %r203
	store %ptr %r203, %ptr* %t10
	br label %L285
L285:
	%r205 = load %ptr, %ptr* %t10
	store %ptr %r205, %ptr* %t9
	br label %L282
L282:
	%r206 = load %ptr, %ptr* %t9
	br label %L278
L278:
	%r207 = load %ptr, %ptr* %t5
	%r208 = load %ptr, %ptr* %t3
	%r212 = ptrtoint %ptr %r208 to %word
	%r211 = ptrtoint %ptr %r207 to %word
	%r210 = icmp sle %word %r212, %r211
	%r209 = inttoptr i1 %r210 to %ptr
	%r214 = ptrtoint %ptr %r209 to %word
	%r213 = icmp ne %word %r214, 0
	br i1 %r213, label %L277, label %L279
L279:
	%r215 = inttoptr %word 0 to %ptr
	%r216 = load %ptr, %ptr* %t1
	%r217 = call %ptr @"new-<symbol>"(%ptr %r216)
	store %ptr %r217, %ptr* %t6
	%r219 = getelementptr %ptr, %ptr* %t6, %word 0
	%r218 = bitcast %ptr* %r219 to %ptr
	%r220 = call %ptr @"gc/push-root"(%ptr %r218)
	%r221 = load %ptr, %ptr* %t4
	%r222 = load %ptr, %ptr* %t3
	%r223 = load %ptr, %ptr* %t6
	%r224 = call %ptr @"k/array-insert"(%ptr %r221, %ptr %r222, %ptr %r223)
	%r225 = load %ptr, %ptr* %t6
	store %ptr %r225, %ptr* %t7
	%r227 = getelementptr %ptr, %ptr* %t6, %word 0
	%r226 = bitcast %ptr* %r227 to %ptr
	%r228 = call %ptr @"gc/pop-root"(%ptr %r226)
	%r229 = load %ptr, %ptr* %t7
	ret %ptr %r229
}
define %ptr @intern(%ptr %cstr) {
	%t1 = alloca %ptr
	store %ptr %cstr, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = load %ptr, %ptr* @"*module*"
	%r3 = call %ptr @"intern*"(%ptr %r1, %ptr %r2)
	ret %ptr %r3
}
define %ptr @is_octal(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	%r3 = inttoptr %word 48 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp sle %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	store %ptr %r4, %ptr* %t2
	%r8 = inttoptr %word 0 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r4 to %word
	%r10 = icmp eq %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	%r14 = ptrtoint %ptr %r9 to %word
	%r13 = icmp ne %word %r14, 0
	br i1 %r13, label %L286, label %L287
L287:
	%r15 = inttoptr %word 55 to %ptr
	%r16 = load %ptr, %ptr* %t1
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp sle %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	store %ptr %r17, %ptr* %t2
	%r21 = inttoptr %word 0 to %ptr
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r25, %r24
	%r22 = inttoptr i1 %r23 to %ptr
	%r27 = ptrtoint %ptr %r22 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L286, label %L288
L288:
	br label %L286
L286:
	%r28 = load %ptr, %ptr* %t2
	ret %ptr %r28
}
define %ptr @is_hexadecimal(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t2
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = inttoptr %word 48 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp sle %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	store %ptr %r5, %ptr* %t3
	%r9 = inttoptr %word 0 to %ptr
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = ptrtoint %ptr %r5 to %word
	%r11 = icmp eq %word %r13, %r12
	%r10 = inttoptr i1 %r11 to %ptr
	%r15 = ptrtoint %ptr %r10 to %word
	%r14 = icmp ne %word %r15, 0
	br i1 %r14, label %L290, label %L291
L291:
	%r16 = inttoptr %word 57 to %ptr
	%r17 = load %ptr, %ptr* %t1
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp sle %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t3
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L290, label %L292
L292:
	br label %L290
L290:
	%r29 = load %ptr, %ptr* %t3
	store %ptr %r29, %ptr* %t2
	%r30 = inttoptr %word 0 to %ptr
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = icmp eq %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	%r36 = ptrtoint %ptr %r31 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L293, label %L289
L293:
	%r37 = inttoptr %word 1 to %ptr
	store %ptr %r37, %ptr* %t3
	%r38 = load %ptr, %ptr* %t1
	%r39 = inttoptr %word 97 to %ptr
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = icmp sle %word %r43, %r42
	%r40 = inttoptr i1 %r41 to %ptr
	store %ptr %r40, %ptr* %t3
	%r44 = inttoptr %word 0 to %ptr
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r40 to %word
	%r46 = icmp eq %word %r48, %r47
	%r45 = inttoptr i1 %r46 to %ptr
	%r50 = ptrtoint %ptr %r45 to %word
	%r49 = icmp ne %word %r50, 0
	br i1 %r49, label %L294, label %L295
L295:
	%r51 = inttoptr %word 102 to %ptr
	%r52 = load %ptr, %ptr* %t1
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = icmp sle %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	store %ptr %r53, %ptr* %t3
	%r57 = inttoptr %word 0 to %ptr
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r53 to %word
	%r59 = icmp eq %word %r61, %r60
	%r58 = inttoptr i1 %r59 to %ptr
	%r63 = ptrtoint %ptr %r58 to %word
	%r62 = icmp ne %word %r63, 0
	br i1 %r62, label %L294, label %L296
L296:
	br label %L294
L294:
	%r64 = load %ptr, %ptr* %t3
	store %ptr %r64, %ptr* %t2
	%r65 = inttoptr %word 0 to %ptr
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = ptrtoint %ptr %r64 to %word
	%r67 = icmp eq %word %r69, %r68
	%r66 = inttoptr i1 %r67 to %ptr
	%r71 = ptrtoint %ptr %r66 to %word
	%r70 = icmp ne %word %r71, 0
	br i1 %r70, label %L297, label %L289
L297:
	%r72 = inttoptr %word 1 to %ptr
	store %ptr %r72, %ptr* %t3
	%r73 = load %ptr, %ptr* %t1
	%r74 = inttoptr %word 65 to %ptr
	%r78 = ptrtoint %ptr %r74 to %word
	%r77 = ptrtoint %ptr %r73 to %word
	%r76 = icmp sle %word %r78, %r77
	%r75 = inttoptr i1 %r76 to %ptr
	store %ptr %r75, %ptr* %t3
	%r79 = inttoptr %word 0 to %ptr
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = ptrtoint %ptr %r75 to %word
	%r81 = icmp eq %word %r83, %r82
	%r80 = inttoptr i1 %r81 to %ptr
	%r85 = ptrtoint %ptr %r80 to %word
	%r84 = icmp ne %word %r85, 0
	br i1 %r84, label %L298, label %L299
L299:
	%r86 = inttoptr %word 70 to %ptr
	%r87 = load %ptr, %ptr* %t1
	%r91 = ptrtoint %ptr %r87 to %word
	%r90 = ptrtoint %ptr %r86 to %word
	%r89 = icmp sle %word %r91, %r90
	%r88 = inttoptr i1 %r89 to %ptr
	store %ptr %r88, %ptr* %t3
	%r92 = inttoptr %word 0 to %ptr
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = ptrtoint %ptr %r88 to %word
	%r94 = icmp eq %word %r96, %r95
	%r93 = inttoptr i1 %r94 to %ptr
	%r98 = ptrtoint %ptr %r93 to %word
	%r97 = icmp ne %word %r98, 0
	br i1 %r97, label %L298, label %L300
L300:
	br label %L298
L298:
	%r99 = load %ptr, %ptr* %t3
	store %ptr %r99, %ptr* %t2
	%r100 = inttoptr %word 0 to %ptr
	%r104 = ptrtoint %ptr %r100 to %word
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = icmp eq %word %r104, %r103
	%r101 = inttoptr i1 %r102 to %ptr
	%r106 = ptrtoint %ptr %r101 to %word
	%r105 = icmp ne %word %r106, 0
	br i1 %r105, label %L301, label %L289
L301:
	br label %L289
L289:
	%r107 = load %ptr, %ptr* %t2
	ret %ptr %r107
}
@str320 = private unnamed_addr constant [38 x i8] c"illegal digit in character escape: %c\00"
define %ptr @digit_value(%ptr %c) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %c, %ptr* %t1
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t3
	%r2 = load %ptr, %ptr* %t1
	%r3 = inttoptr %word 48 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp sle %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r4 to %word
	%r10 = icmp eq %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	%r14 = ptrtoint %ptr %r9 to %word
	%r13 = icmp ne %word %r14, 0
	br i1 %r13, label %L305, label %L306
L306:
	%r15 = inttoptr %word 57 to %ptr
	%r16 = load %ptr, %ptr* %t1
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp sle %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	store %ptr %r17, %ptr* %t3
	%r21 = inttoptr %word 0 to %ptr
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r25, %r24
	%r22 = inttoptr i1 %r23 to %ptr
	%r27 = ptrtoint %ptr %r22 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L305, label %L307
L307:
	br label %L305
L305:
	%r28 = load %ptr, %ptr* %t3
	%r30 = ptrtoint %ptr %r28 to %word
	%r29 = icmp ne %word %r30, 0
	br i1 %r29, label %L302, label %L303
L302:
	%r31 = inttoptr %word 48 to %ptr
	%r32 = load %ptr, %ptr* %t1
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = sub %word %r36, %r35
	%r33 = inttoptr %word %r34 to %ptr
	store %ptr %r33, %ptr* %t2
	br label %L304
L303:
	%r37 = inttoptr %word 1 to %ptr
	store %ptr %r37, %ptr* %t4
	%r38 = load %ptr, %ptr* %t1
	%r39 = inttoptr %word 97 to %ptr
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = icmp sle %word %r43, %r42
	%r40 = inttoptr i1 %r41 to %ptr
	store %ptr %r40, %ptr* %t4
	%r44 = inttoptr %word 0 to %ptr
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r40 to %word
	%r46 = icmp eq %word %r48, %r47
	%r45 = inttoptr i1 %r46 to %ptr
	%r50 = ptrtoint %ptr %r45 to %word
	%r49 = icmp ne %word %r50, 0
	br i1 %r49, label %L311, label %L312
L312:
	%r51 = inttoptr %word 122 to %ptr
	%r52 = load %ptr, %ptr* %t1
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = icmp sle %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	store %ptr %r53, %ptr* %t4
	%r57 = inttoptr %word 0 to %ptr
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r53 to %word
	%r59 = icmp eq %word %r61, %r60
	%r58 = inttoptr i1 %r59 to %ptr
	%r63 = ptrtoint %ptr %r58 to %word
	%r62 = icmp ne %word %r63, 0
	br i1 %r62, label %L311, label %L313
L313:
	br label %L311
L311:
	%r64 = load %ptr, %ptr* %t4
	%r66 = ptrtoint %ptr %r64 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L308, label %L309
L308:
	%r67 = inttoptr %word 10 to %ptr
	%r68 = inttoptr %word 97 to %ptr
	%r72 = ptrtoint %ptr %r68 to %word
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = sub %word %r72, %r71
	%r69 = inttoptr %word %r70 to %ptr
	%r73 = load %ptr, %ptr* %t1
	%r77 = ptrtoint %ptr %r73 to %word
	%r76 = ptrtoint %ptr %r69 to %word
	%r75 = sub %word %r77, %r76
	%r74 = inttoptr %word %r75 to %ptr
	store %ptr %r74, %ptr* %t3
	br label %L310
L309:
	%r78 = inttoptr %word 1 to %ptr
	store %ptr %r78, %ptr* %t5
	%r79 = load %ptr, %ptr* %t1
	%r80 = inttoptr %word 65 to %ptr
	%r84 = ptrtoint %ptr %r80 to %word
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = icmp sle %word %r84, %r83
	%r81 = inttoptr i1 %r82 to %ptr
	store %ptr %r81, %ptr* %t5
	%r85 = inttoptr %word 0 to %ptr
	%r89 = ptrtoint %ptr %r85 to %word
	%r88 = ptrtoint %ptr %r81 to %word
	%r87 = icmp eq %word %r89, %r88
	%r86 = inttoptr i1 %r87 to %ptr
	%r91 = ptrtoint %ptr %r86 to %word
	%r90 = icmp ne %word %r91, 0
	br i1 %r90, label %L317, label %L318
L318:
	%r92 = inttoptr %word 90 to %ptr
	%r93 = load %ptr, %ptr* %t1
	%r97 = ptrtoint %ptr %r93 to %word
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = icmp sle %word %r97, %r96
	%r94 = inttoptr i1 %r95 to %ptr
	store %ptr %r94, %ptr* %t5
	%r98 = inttoptr %word 0 to %ptr
	%r102 = ptrtoint %ptr %r98 to %word
	%r101 = ptrtoint %ptr %r94 to %word
	%r100 = icmp eq %word %r102, %r101
	%r99 = inttoptr i1 %r100 to %ptr
	%r104 = ptrtoint %ptr %r99 to %word
	%r103 = icmp ne %word %r104, 0
	br i1 %r103, label %L317, label %L319
L319:
	br label %L317
L317:
	%r105 = load %ptr, %ptr* %t5
	%r107 = ptrtoint %ptr %r105 to %word
	%r106 = icmp ne %word %r107, 0
	br i1 %r106, label %L314, label %L315
L314:
	%r108 = inttoptr %word 10 to %ptr
	%r109 = inttoptr %word 65 to %ptr
	%r113 = ptrtoint %ptr %r109 to %word
	%r112 = ptrtoint %ptr %r108 to %word
	%r111 = sub %word %r113, %r112
	%r110 = inttoptr %word %r111 to %ptr
	%r114 = load %ptr, %ptr* %t1
	%r118 = ptrtoint %ptr %r114 to %word
	%r117 = ptrtoint %ptr %r110 to %word
	%r116 = sub %word %r118, %r117
	%r115 = inttoptr %word %r116 to %ptr
	store %ptr %r115, %ptr* %t4
	br label %L316
L315:
	%r119 = getelementptr [38 x i8], [38 x i8]* @str320, %word 0, %word 0
	%r121 = load %ptr, %ptr* %t1
	%r122 = call %ptr @fatal1(%ptr %r119, %ptr %r121)
	store %ptr %r122, %ptr* %t4
	br label %L316
L316:
	%r123 = load %ptr, %ptr* %t4
	store %ptr %r123, %ptr* %t3
	br label %L310
L310:
	%r124 = load %ptr, %ptr* %t3
	store %ptr %r124, %ptr* %t2
	br label %L304
L304:
	%r125 = load %ptr, %ptr* %t2
	ret %ptr %r125
}
@str391 = private unnamed_addr constant [37 x i8] c"error while reading from libc stream\00"
@str392 = private unnamed_addr constant [22 x i8] c"illegal character: %c\00"
define %ptr @"k/read"(%ptr %stream) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	%t12 = alloca %ptr
	%t13 = alloca %ptr
	%t14 = alloca %ptr
	%t15 = alloca %ptr
	%t16 = alloca %ptr
	%t17 = alloca %ptr
	%t18 = alloca %ptr
	%t19 = alloca %ptr
	%t20 = alloca %ptr
	store %ptr %stream, %ptr* %t1
	br label %L322
L321:
	%r1 = load %ptr, %ptr* %t1
	%r2 = call i32 @fgetc(%ptr %r1)
	%r3 = inttoptr %word %r2 to %ptr
	store %ptr %r3, %ptr* %t2
	%r4 = load %ptr, %ptr* %t2
	%r5 = call %ptr @is_blank(%ptr %r4)
	%r7 = ptrtoint %ptr %r5 to %word
	%r6 = icmp ne %word %r7, 0
	br i1 %r6, label %L324, label %L325
L324:
	%r8 = inttoptr %word 0 to %ptr
	store %ptr %r8, %ptr* %t3
	br label %L326
L325:
	%r9 = load %ptr, %ptr* %t2
	%r10 = inttoptr %word 63 to %ptr
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = icmp eq %word %r14, %r13
	%r11 = inttoptr i1 %r12 to %ptr
	%r16 = ptrtoint %ptr %r11 to %word
	%r15 = icmp ne %word %r16, 0
	br i1 %r15, label %L327, label %L328
L327:
	%r17 = inttoptr %word 1 to %ptr
	%r18 = inttoptr %word 1 to %ptr
	%r19 = load %ptr, %ptr* %t1
	%r20 = call i32 @fgetc(%ptr %r19)
	%r21 = inttoptr %word %r20 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r23 = call %ptr @read_char(%ptr %r21, %ptr %r22)
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r18 to %word
	%r25 = shl %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r31 = ptrtoint %ptr %r24 to %word
	%r30 = ptrtoint %ptr %r17 to %word
	%r29 = add %word %r31, %r30
	%r28 = inttoptr %word %r29 to %ptr
	ret %ptr %r28
	store %ptr %r28, %ptr* %t4
	br label %L329
L328:
	%r33 = load %ptr, %ptr* %t2
	%r34 = inttoptr %word 45 to %ptr
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r33 to %word
	%r36 = icmp eq %word %r38, %r37
	%r35 = inttoptr i1 %r36 to %ptr
	%r40 = ptrtoint %ptr %r35 to %word
	%r39 = icmp ne %word %r40, 0
	br i1 %r39, label %L330, label %L331
L330:
	%r41 = load %ptr, %ptr* %t1
	%r42 = call i32 @fgetc(%ptr %r41)
	%r43 = inttoptr %word %r42 to %ptr
	%r44 = load %ptr, %ptr* %t1
	%ffi-cast45 = ptrtoint %ptr %r43 to i32
	%r46 = call i32 @ungetc(i32 %ffi-cast45, %ptr %r44)
	%r47 = inttoptr %word %r46 to %ptr
	%r48 = call %ptr @is_digit10(%ptr %r47)
	%r50 = ptrtoint %ptr %r48 to %word
	%r49 = icmp ne %word %r50, 0
	br i1 %r49, label %L333, label %L334
L333:
	%r51 = load %ptr, %ptr* %t2
	%r52 = load %ptr, %ptr* %t1
	%r53 = call %ptr @read_number(%ptr %r51, %ptr %r52)
	store %ptr %r53, %ptr* %t6
	br label %L335
L334:
	%r54 = load %ptr, %ptr* %t2
	%r55 = load %ptr, %ptr* %t1
	%r56 = call %ptr @read_symbol(%ptr %r54, %ptr %r55)
	store %ptr %r56, %ptr* %t6
	br label %L335
L335:
	%r57 = load %ptr, %ptr* %t6
	ret %ptr %r57
	store %ptr %r57, %ptr* %t5
	br label %L332
L331:
	%r59 = load %ptr, %ptr* %t2
	%r60 = inttoptr %word 39 to %ptr
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = icmp eq %word %r64, %r63
	%r61 = inttoptr i1 %r62 to %ptr
	%r66 = ptrtoint %ptr %r61 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L336, label %L337
L336:
	%r67 = load %ptr, %ptr* @"symbol/quote"
	%r68 = load %ptr, %ptr* %t1
	%r69 = call %ptr @read_quote(%ptr %r67, %ptr %r68)
	ret %ptr %r69
	store %ptr %r69, %ptr* %t6
	br label %L338
L337:
	%r71 = load %ptr, %ptr* %t2
	%r72 = inttoptr %word 96 to %ptr
	%r76 = ptrtoint %ptr %r72 to %word
	%r75 = ptrtoint %ptr %r71 to %word
	%r74 = icmp eq %word %r76, %r75
	%r73 = inttoptr i1 %r74 to %ptr
	%r78 = ptrtoint %ptr %r73 to %word
	%r77 = icmp ne %word %r78, 0
	br i1 %r77, label %L339, label %L340
L339:
	%r79 = load %ptr, %ptr* @"symbol/quasiquote"
	%r80 = load %ptr, %ptr* %t1
	%r81 = call %ptr @read_quote(%ptr %r79, %ptr %r80)
	ret %ptr %r81
	store %ptr %r81, %ptr* %t7
	br label %L341
L340:
	%r83 = load %ptr, %ptr* %t2
	%r84 = inttoptr %word 44 to %ptr
	%r88 = ptrtoint %ptr %r84 to %word
	%r87 = ptrtoint %ptr %r83 to %word
	%r86 = icmp eq %word %r88, %r87
	%r85 = inttoptr i1 %r86 to %ptr
	%r90 = ptrtoint %ptr %r85 to %word
	%r89 = icmp ne %word %r90, 0
	br i1 %r89, label %L342, label %L343
L342:
	%r91 = load %ptr, %ptr* %t1
	%r92 = call i32 @fgetc(%ptr %r91)
	%r93 = inttoptr %word %r92 to %ptr
	store %ptr %r93, %ptr* %t9
	%r94 = load %ptr, %ptr* %t9
	%r95 = inttoptr %word 64 to %ptr
	%r99 = ptrtoint %ptr %r95 to %word
	%r98 = ptrtoint %ptr %r94 to %word
	%r97 = icmp eq %word %r99, %r98
	%r96 = inttoptr i1 %r97 to %ptr
	%r101 = ptrtoint %ptr %r96 to %word
	%r100 = icmp ne %word %r101, 0
	br i1 %r100, label %L345, label %L346
L345:
	%r102 = load %ptr, %ptr* @"symbol/unquote_splicing"
	%r103 = load %ptr, %ptr* %t1
	%r104 = call %ptr @read_quote(%ptr %r102, %ptr %r103)
	store %ptr %r104, %ptr* %t10
	br label %L347
L346:
	%r105 = load %ptr, %ptr* %t9
	%r106 = load %ptr, %ptr* %t1
	%ffi-cast107 = ptrtoint %ptr %r105 to i32
	%r108 = call i32 @ungetc(i32 %ffi-cast107, %ptr %r106)
	%r109 = inttoptr %word %r108 to %ptr
	%r110 = load %ptr, %ptr* @"symbol/unquote"
	%r111 = load %ptr, %ptr* %t1
	%r112 = call %ptr @read_quote(%ptr %r110, %ptr %r111)
	store %ptr %r112, %ptr* %t10
	br label %L347
L347:
	%r113 = load %ptr, %ptr* %t10
	ret %ptr %r113
	store %ptr %r113, %ptr* %t8
	br label %L344
L343:
	%r115 = load %ptr, %ptr* %t2
	%r116 = call %ptr @is_letter(%ptr %r115)
	%r118 = ptrtoint %ptr %r116 to %word
	%r117 = icmp ne %word %r118, 0
	br i1 %r117, label %L348, label %L349
L348:
	%r119 = load %ptr, %ptr* %t2
	%r120 = load %ptr, %ptr* %t1
	%r121 = call %ptr @read_symbol(%ptr %r119, %ptr %r120)
	ret %ptr %r121
	store %ptr %r121, %ptr* %t9
	br label %L350
L349:
	%r123 = load %ptr, %ptr* %t2
	%r124 = inttoptr %word 40 to %ptr
	%r128 = ptrtoint %ptr %r124 to %word
	%r127 = ptrtoint %ptr %r123 to %word
	%r126 = icmp eq %word %r128, %r127
	%r125 = inttoptr i1 %r126 to %ptr
	%r130 = ptrtoint %ptr %r125 to %word
	%r129 = icmp ne %word %r130, 0
	br i1 %r129, label %L351, label %L352
L351:
	%r131 = inttoptr %word 41 to %ptr
	%r132 = load %ptr, %ptr* %t1
	%r133 = call %ptr @read_list(%ptr %r131, %ptr %r132)
	ret %ptr %r133
	store %ptr %r133, %ptr* %t10
	br label %L353
L352:
	%r135 = load %ptr, %ptr* %t2
	%r136 = inttoptr %word 41 to %ptr
	%r140 = ptrtoint %ptr %r136 to %word
	%r139 = ptrtoint %ptr %r135 to %word
	%r138 = icmp eq %word %r140, %r139
	%r137 = inttoptr i1 %r138 to %ptr
	%r142 = ptrtoint %ptr %r137 to %word
	%r141 = icmp ne %word %r142, 0
	br i1 %r141, label %L354, label %L355
L354:
	%r143 = load %ptr, %ptr* %t2
	%r144 = load %ptr, %ptr* %t1
	%ffi-cast145 = ptrtoint %ptr %r143 to i32
	%r146 = call i32 @ungetc(i32 %ffi-cast145, %ptr %r144)
	%r147 = inttoptr %word %r146 to %ptr
	%r148 = load %ptr, %ptr* @"k/+done+"
	ret %ptr %r148
	store %ptr %r148, %ptr* %t11
	br label %L356
L355:
	%r150 = load %ptr, %ptr* %t2
	%r151 = inttoptr %word 91 to %ptr
	%r155 = ptrtoint %ptr %r151 to %word
	%r154 = ptrtoint %ptr %r150 to %word
	%r153 = icmp eq %word %r155, %r154
	%r152 = inttoptr i1 %r153 to %ptr
	%r157 = ptrtoint %ptr %r152 to %word
	%r156 = icmp ne %word %r157, 0
	br i1 %r156, label %L357, label %L358
L357:
	%r158 = inttoptr %word 93 to %ptr
	%r159 = load %ptr, %ptr* %t1
	%r160 = call %ptr @read_list(%ptr %r158, %ptr %r159)
	ret %ptr %r160
	store %ptr %r160, %ptr* %t12
	br label %L359
L358:
	%r162 = load %ptr, %ptr* %t2
	%r163 = inttoptr %word 93 to %ptr
	%r167 = ptrtoint %ptr %r163 to %word
	%r166 = ptrtoint %ptr %r162 to %word
	%r165 = icmp eq %word %r167, %r166
	%r164 = inttoptr i1 %r165 to %ptr
	%r169 = ptrtoint %ptr %r164 to %word
	%r168 = icmp ne %word %r169, 0
	br i1 %r168, label %L360, label %L361
L360:
	%r170 = load %ptr, %ptr* %t2
	%r171 = load %ptr, %ptr* %t1
	%ffi-cast172 = ptrtoint %ptr %r170 to i32
	%r173 = call i32 @ungetc(i32 %ffi-cast172, %ptr %r171)
	%r174 = inttoptr %word %r173 to %ptr
	%r175 = load %ptr, %ptr* @"k/+done+"
	ret %ptr %r175
	store %ptr %r175, %ptr* %t13
	br label %L362
L361:
	%r177 = load %ptr, %ptr* %t2
	%r178 = inttoptr %word 123 to %ptr
	%r182 = ptrtoint %ptr %r178 to %word
	%r181 = ptrtoint %ptr %r177 to %word
	%r180 = icmp eq %word %r182, %r181
	%r179 = inttoptr i1 %r180 to %ptr
	%r184 = ptrtoint %ptr %r179 to %word
	%r183 = icmp ne %word %r184, 0
	br i1 %r183, label %L363, label %L364
L363:
	%r185 = inttoptr %word 125 to %ptr
	%r186 = load %ptr, %ptr* %t1
	%r187 = call %ptr @read_list(%ptr %r185, %ptr %r186)
	ret %ptr %r187
	store %ptr %r187, %ptr* %t14
	br label %L365
L364:
	%r189 = load %ptr, %ptr* %t2
	%r190 = inttoptr %word 125 to %ptr
	%r194 = ptrtoint %ptr %r190 to %word
	%r193 = ptrtoint %ptr %r189 to %word
	%r192 = icmp eq %word %r194, %r193
	%r191 = inttoptr i1 %r192 to %ptr
	%r196 = ptrtoint %ptr %r191 to %word
	%r195 = icmp ne %word %r196, 0
	br i1 %r195, label %L366, label %L367
L366:
	%r197 = load %ptr, %ptr* %t2
	%r198 = load %ptr, %ptr* %t1
	%ffi-cast199 = ptrtoint %ptr %r197 to i32
	%r200 = call i32 @ungetc(i32 %ffi-cast199, %ptr %r198)
	%r201 = inttoptr %word %r200 to %ptr
	%r202 = load %ptr, %ptr* @"k/+done+"
	ret %ptr %r202
	store %ptr %r202, %ptr* %t15
	br label %L368
L367:
	%r204 = load %ptr, %ptr* %t2
	%r205 = call %ptr @is_digit10(%ptr %r204)
	%r207 = ptrtoint %ptr %r205 to %word
	%r206 = icmp ne %word %r207, 0
	br i1 %r206, label %L369, label %L370
L369:
	%r208 = load %ptr, %ptr* %t2
	%r209 = load %ptr, %ptr* %t1
	%r210 = call %ptr @read_number(%ptr %r208, %ptr %r209)
	ret %ptr %r210
	store %ptr %r210, %ptr* %t16
	br label %L371
L370:
	%r212 = load %ptr, %ptr* %t2
	%r213 = inttoptr %word 59 to %ptr
	%r217 = ptrtoint %ptr %r213 to %word
	%r216 = ptrtoint %ptr %r212 to %word
	%r215 = icmp eq %word %r217, %r216
	%r214 = inttoptr i1 %r215 to %ptr
	%r219 = ptrtoint %ptr %r214 to %word
	%r218 = icmp ne %word %r219, 0
	br i1 %r218, label %L372, label %L373
L372:
	br label %L376
L375:
	br label %L376
L376:
	%r220 = inttoptr %word 1 to %ptr
	store %ptr %r220, %ptr* %t18
	%r221 = load %ptr, %ptr* %t1
	%r222 = call i32 @fgetc(%ptr %r221)
	%r223 = inttoptr %word %r222 to %ptr
	store %ptr %r223, %ptr* %t2
	%r224 = inttoptr %word 10 to %ptr
	%r228 = ptrtoint %ptr %r224 to %word
	%r227 = ptrtoint %ptr %r223 to %word
	%r226 = icmp ne %word %r228, %r227
	%r225 = inttoptr i1 %r226 to %ptr
	store %ptr %r225, %ptr* %t18
	%r229 = inttoptr %word 0 to %ptr
	%r233 = ptrtoint %ptr %r229 to %word
	%r232 = ptrtoint %ptr %r225 to %word
	%r231 = icmp eq %word %r233, %r232
	%r230 = inttoptr i1 %r231 to %ptr
	%r235 = ptrtoint %ptr %r230 to %word
	%r234 = icmp ne %word %r235, 0
	br i1 %r234, label %L378, label %L379
L379:
	%r236 = load %ptr, %ptr* %t2
	%r237 = inttoptr %word 13 to %ptr
	%r241 = ptrtoint %ptr %r237 to %word
	%r240 = ptrtoint %ptr %r236 to %word
	%r239 = icmp ne %word %r241, %r240
	%r238 = inttoptr i1 %r239 to %ptr
	store %ptr %r238, %ptr* %t18
	%r242 = inttoptr %word 0 to %ptr
	%r246 = ptrtoint %ptr %r242 to %word
	%r245 = ptrtoint %ptr %r238 to %word
	%r244 = icmp eq %word %r246, %r245
	%r243 = inttoptr i1 %r244 to %ptr
	%r248 = ptrtoint %ptr %r243 to %word
	%r247 = icmp ne %word %r248, 0
	br i1 %r247, label %L378, label %L380
L380:
	%r249 = load %ptr, %ptr* %t2
	%r250 = inttoptr %word -1 to %ptr
	%r254 = ptrtoint %ptr %r250 to %word
	%r253 = ptrtoint %ptr %r249 to %word
	%r252 = icmp ne %word %r254, %r253
	%r251 = inttoptr i1 %r252 to %ptr
	store %ptr %r251, %ptr* %t18
	%r255 = inttoptr %word 0 to %ptr
	%r259 = ptrtoint %ptr %r255 to %word
	%r258 = ptrtoint %ptr %r251 to %word
	%r257 = icmp eq %word %r259, %r258
	%r256 = inttoptr i1 %r257 to %ptr
	%r261 = ptrtoint %ptr %r256 to %word
	%r260 = icmp ne %word %r261, 0
	br i1 %r260, label %L378, label %L381
L381:
	br label %L378
L378:
	%r262 = load %ptr, %ptr* %t18
	%r264 = ptrtoint %ptr %r262 to %word
	%r263 = icmp ne %word %r264, 0
	br i1 %r263, label %L375, label %L377
L377:
	store %ptr %r262, %ptr* %t17
	br label %L374
L373:
	%r265 = load %ptr, %ptr* %t2
	%r266 = inttoptr %word 34 to %ptr
	%r270 = ptrtoint %ptr %r266 to %word
	%r269 = ptrtoint %ptr %r265 to %word
	%r268 = icmp eq %word %r270, %r269
	%r267 = inttoptr i1 %r268 to %ptr
	%r272 = ptrtoint %ptr %r267 to %word
	%r271 = icmp ne %word %r272, 0
	br i1 %r271, label %L382, label %L383
L382:
	%r273 = load %ptr, %ptr* %t2
	%r274 = load %ptr, %ptr* %t1
	%r275 = call %ptr @read_string(%ptr %r273, %ptr %r274)
	ret %ptr %r275
	store %ptr %r275, %ptr* %t18
	br label %L384
L383:
	%r277 = inttoptr %word -1 to %ptr
	%r278 = load %ptr, %ptr* %t2
	%r282 = ptrtoint %ptr %r278 to %word
	%r281 = ptrtoint %ptr %r277 to %word
	%r280 = icmp eq %word %r282, %r281
	%r279 = inttoptr i1 %r280 to %ptr
	%r284 = ptrtoint %ptr %r279 to %word
	%r283 = icmp ne %word %r284, 0
	br i1 %r283, label %L385, label %L386
L385:
	%r285 = load %ptr, %ptr* %t1
	%r286 = call i32 @feof(%ptr %r285)
	%r287 = inttoptr %word %r286 to %ptr
	%r289 = ptrtoint %ptr %r287 to %word
	%r288 = icmp ne %word %r289, 0
	br i1 %r288, label %L388, label %L389
L388:
	%r290 = load %ptr, %ptr* @"k/+done+"
	ret %ptr %r290
	store %ptr %r290, %ptr* %t20
	br label %L390
L389:
	%r292 = getelementptr [37 x i8], [37 x i8]* @str391, %word 0, %word 0
	%r294 = call %ptr @fatal(%ptr %r292)
	store %ptr %r294, %ptr* %t20
	br label %L390
L390:
	%r295 = load %ptr, %ptr* %t20
	store %ptr %r295, %ptr* %t19
	br label %L387
L386:
	%r296 = getelementptr [22 x i8], [22 x i8]* @str392, %word 0, %word 0
	%r298 = load %ptr, %ptr* %t2
	%r299 = call %ptr @fatal1(%ptr %r296, %ptr %r298)
	store %ptr %r299, %ptr* %t19
	br label %L387
L387:
	%r300 = load %ptr, %ptr* %t19
	store %ptr %r300, %ptr* %t18
	br label %L384
L384:
	%r301 = load %ptr, %ptr* %t18
	store %ptr %r301, %ptr* %t17
	br label %L374
L374:
	%r302 = load %ptr, %ptr* %t17
	store %ptr %r302, %ptr* %t16
	br label %L371
L371:
	%r303 = load %ptr, %ptr* %t16
	store %ptr %r303, %ptr* %t15
	br label %L368
L368:
	%r304 = load %ptr, %ptr* %t15
	store %ptr %r304, %ptr* %t14
	br label %L365
L365:
	%r305 = load %ptr, %ptr* %t14
	store %ptr %r305, %ptr* %t13
	br label %L362
L362:
	%r306 = load %ptr, %ptr* %t13
	store %ptr %r306, %ptr* %t12
	br label %L359
L359:
	%r307 = load %ptr, %ptr* %t12
	store %ptr %r307, %ptr* %t11
	br label %L356
L356:
	%r308 = load %ptr, %ptr* %t11
	store %ptr %r308, %ptr* %t10
	br label %L353
L353:
	%r309 = load %ptr, %ptr* %t10
	store %ptr %r309, %ptr* %t9
	br label %L350
L350:
	%r310 = load %ptr, %ptr* %t9
	store %ptr %r310, %ptr* %t8
	br label %L344
L344:
	%r311 = load %ptr, %ptr* %t8
	store %ptr %r311, %ptr* %t7
	br label %L341
L341:
	%r312 = load %ptr, %ptr* %t7
	store %ptr %r312, %ptr* %t6
	br label %L338
L338:
	%r313 = load %ptr, %ptr* %t6
	store %ptr %r313, %ptr* %t5
	br label %L332
L332:
	%r314 = load %ptr, %ptr* %t5
	store %ptr %r314, %ptr* %t4
	br label %L329
L329:
	%r315 = load %ptr, %ptr* %t4
	store %ptr %r315, %ptr* %t3
	br label %L326
L326:
	%r316 = load %ptr, %ptr* %t3
	br label %L322
L322:
	%r317 = inttoptr %word 1 to %ptr
	%r319 = ptrtoint %ptr %r317 to %word
	%r318 = icmp ne %word %r319, 0
	br i1 %r318, label %L321, label %L323
L323:
	ret %ptr %r317
}
@str427 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str428 = private unnamed_addr constant [25 x i8] c"illegal character escape\00"
@str429 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str440 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str441 = private unnamed_addr constant [25 x i8] c"illegal character escape\00"
@str442 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str455 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str456 = private unnamed_addr constant [25 x i8] c"illegal character escape\00"
@str457 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str464 = private unnamed_addr constant [30 x i8] c"illegal character escape: \5C%c\00"
define %ptr @read_char(%ptr %c, %ptr %stream) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	%t15 = alloca %ptr
	%t14 = alloca %ptr
	%t13 = alloca %ptr
	%t12 = alloca %ptr
	%t16 = alloca %ptr
	%t17 = alloca %ptr
	store %ptr %c, %ptr* %t1
	store %ptr %stream, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = inttoptr %word 92 to %ptr
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = icmp eq %word %r6, %r5
	%r3 = inttoptr i1 %r4 to %ptr
	%r8 = ptrtoint %ptr %r3 to %word
	%r7 = icmp ne %word %r8, 0
	br i1 %r7, label %L393, label %L394
L393:
	%r9 = load %ptr, %ptr* %t2
	%r10 = call i32 @fgetc(%ptr %r9)
	%r11 = inttoptr %word %r10 to %ptr
	store %ptr %r11, %ptr* %t1
	%r12 = inttoptr %word 97 to %ptr
	%r13 = load %ptr, %ptr* %t1
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = icmp eq %word %r17, %r16
	%r14 = inttoptr i1 %r15 to %ptr
	%r19 = ptrtoint %ptr %r14 to %word
	%r18 = icmp ne %word %r19, 0
	br i1 %r18, label %L396, label %L397
L396:
	%r20 = inttoptr %word 7 to %ptr
	store %ptr %r20, %ptr* %t4
	br label %L398
L397:
	%r21 = inttoptr %word 98 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L399, label %L400
L399:
	%r29 = inttoptr %word 8 to %ptr
	store %ptr %r29, %ptr* %t5
	br label %L401
L400:
	%r30 = inttoptr %word 102 to %ptr
	%r31 = load %ptr, %ptr* %t1
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = icmp eq %word %r35, %r34
	%r32 = inttoptr i1 %r33 to %ptr
	%r37 = ptrtoint %ptr %r32 to %word
	%r36 = icmp ne %word %r37, 0
	br i1 %r36, label %L402, label %L403
L402:
	%r38 = inttoptr %word 12 to %ptr
	store %ptr %r38, %ptr* %t6
	br label %L404
L403:
	%r39 = inttoptr %word 110 to %ptr
	%r40 = load %ptr, %ptr* %t1
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = icmp eq %word %r44, %r43
	%r41 = inttoptr i1 %r42 to %ptr
	%r46 = ptrtoint %ptr %r41 to %word
	%r45 = icmp ne %word %r46, 0
	br i1 %r45, label %L405, label %L406
L405:
	%r47 = inttoptr %word 10 to %ptr
	store %ptr %r47, %ptr* %t7
	br label %L407
L406:
	%r48 = inttoptr %word 114 to %ptr
	%r49 = load %ptr, %ptr* %t1
	%r53 = ptrtoint %ptr %r49 to %word
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = icmp eq %word %r53, %r52
	%r50 = inttoptr i1 %r51 to %ptr
	%r55 = ptrtoint %ptr %r50 to %word
	%r54 = icmp ne %word %r55, 0
	br i1 %r54, label %L408, label %L409
L408:
	%r56 = inttoptr %word 13 to %ptr
	store %ptr %r56, %ptr* %t8
	br label %L410
L409:
	%r57 = inttoptr %word 116 to %ptr
	%r58 = load %ptr, %ptr* %t1
	%r62 = ptrtoint %ptr %r58 to %word
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = icmp eq %word %r62, %r61
	%r59 = inttoptr i1 %r60 to %ptr
	%r64 = ptrtoint %ptr %r59 to %word
	%r63 = icmp ne %word %r64, 0
	br i1 %r63, label %L411, label %L412
L411:
	%r65 = inttoptr %word 9 to %ptr
	store %ptr %r65, %ptr* %t9
	br label %L413
L412:
	%r66 = inttoptr %word 118 to %ptr
	%r67 = load %ptr, %ptr* %t1
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = icmp eq %word %r71, %r70
	%r68 = inttoptr i1 %r69 to %ptr
	%r73 = ptrtoint %ptr %r68 to %word
	%r72 = icmp ne %word %r73, 0
	br i1 %r72, label %L414, label %L415
L414:
	%r74 = inttoptr %word 11 to %ptr
	store %ptr %r74, %ptr* %t10
	br label %L416
L415:
	%r75 = inttoptr %word 117 to %ptr
	%r76 = load %ptr, %ptr* %t1
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = icmp eq %word %r80, %r79
	%r77 = inttoptr i1 %r78 to %ptr
	%r82 = ptrtoint %ptr %r77 to %word
	%r81 = icmp ne %word %r82, 0
	br i1 %r81, label %L417, label %L418
L417:
	%r83 = load %ptr, %ptr* %t2
	%r84 = call i32 @fgetc(%ptr %r83)
	%r85 = inttoptr %word %r84 to %ptr
	store %ptr %r85, %ptr* %t12
	%r86 = load %ptr, %ptr* %t2
	%r87 = call i32 @fgetc(%ptr %r86)
	%r88 = inttoptr %word %r87 to %ptr
	store %ptr %r88, %ptr* %t13
	%r89 = load %ptr, %ptr* %t2
	%r90 = call i32 @fgetc(%ptr %r89)
	%r91 = inttoptr %word %r90 to %ptr
	store %ptr %r91, %ptr* %t14
	%r92 = load %ptr, %ptr* %t2
	%r93 = call i32 @fgetc(%ptr %r92)
	%r94 = inttoptr %word %r93 to %ptr
	store %ptr %r94, %ptr* %t15
	%r95 = inttoptr %word 0 to %ptr
	store %ptr %r95, %ptr* %t16
	%r96 = inttoptr %word 1 to %ptr
	store %ptr %r96, %ptr* %t17
	%r97 = load %ptr, %ptr* %t12
	%r98 = call %ptr @is_hexadecimal(%ptr %r97)
	store %ptr %r98, %ptr* %t17
	%r99 = inttoptr %word 0 to %ptr
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = ptrtoint %ptr %r98 to %word
	%r101 = icmp eq %word %r103, %r102
	%r100 = inttoptr i1 %r101 to %ptr
	%r105 = ptrtoint %ptr %r100 to %word
	%r104 = icmp ne %word %r105, 0
	br i1 %r104, label %L421, label %L422
L422:
	%r106 = load %ptr, %ptr* %t13
	%r107 = call %ptr @is_hexadecimal(%ptr %r106)
	store %ptr %r107, %ptr* %t17
	%r108 = inttoptr %word 0 to %ptr
	%r112 = ptrtoint %ptr %r108 to %word
	%r111 = ptrtoint %ptr %r107 to %word
	%r110 = icmp eq %word %r112, %r111
	%r109 = inttoptr i1 %r110 to %ptr
	%r114 = ptrtoint %ptr %r109 to %word
	%r113 = icmp ne %word %r114, 0
	br i1 %r113, label %L421, label %L423
L423:
	%r115 = load %ptr, %ptr* %t14
	%r116 = call %ptr @is_hexadecimal(%ptr %r115)
	store %ptr %r116, %ptr* %t17
	%r117 = inttoptr %word 0 to %ptr
	%r121 = ptrtoint %ptr %r117 to %word
	%r120 = ptrtoint %ptr %r116 to %word
	%r119 = icmp eq %word %r121, %r120
	%r118 = inttoptr i1 %r119 to %ptr
	%r123 = ptrtoint %ptr %r118 to %word
	%r122 = icmp ne %word %r123, 0
	br i1 %r122, label %L421, label %L424
L424:
	%r124 = load %ptr, %ptr* %t15
	%r125 = call %ptr @is_hexadecimal(%ptr %r124)
	store %ptr %r125, %ptr* %t17
	%r126 = inttoptr %word 0 to %ptr
	%r130 = ptrtoint %ptr %r126 to %word
	%r129 = ptrtoint %ptr %r125 to %word
	%r128 = icmp eq %word %r130, %r129
	%r127 = inttoptr i1 %r128 to %ptr
	%r132 = ptrtoint %ptr %r127 to %word
	%r131 = icmp ne %word %r132, 0
	br i1 %r131, label %L421, label %L425
L425:
	br label %L421
L421:
	%r133 = load %ptr, %ptr* %t17
	store %ptr %r133, %ptr* %t16
	%r134 = inttoptr %word 0 to %ptr
	%r138 = ptrtoint %ptr %r134 to %word
	%r137 = ptrtoint %ptr %r133 to %word
	%r136 = icmp eq %word %r138, %r137
	%r135 = inttoptr i1 %r136 to %ptr
	%r140 = ptrtoint %ptr %r135 to %word
	%r139 = icmp ne %word %r140, 0
	br i1 %r139, label %L426, label %L420
L426:
	%r141 = getelementptr [9 x i8], [9 x i8]* @str427, %word 0, %word 0
	%r143 = call i32 (%ptr, ...) @printf(%ptr %r141)
	%r144 = inttoptr %word %r143 to %ptr
	%r145 = getelementptr [25 x i8], [25 x i8]* @str428, %word 0, %word 0
	%r147 = call i32 (%ptr, ...) @printf(%ptr %r145)
	%r148 = inttoptr %word %r147 to %ptr
	%r149 = getelementptr [2 x i8], [2 x i8]* @str429, %word 0, %word 0
	%r151 = call i32 (%ptr, ...) @printf(%ptr %r149)
	%r152 = inttoptr %word %r151 to %ptr
	%r153 = call %ptr @die()
	store %ptr %r153, %ptr* %t16
	%r154 = inttoptr %word 0 to %ptr
	%r158 = ptrtoint %ptr %r154 to %word
	%r157 = ptrtoint %ptr %r153 to %word
	%r156 = icmp eq %word %r158, %r157
	%r155 = inttoptr i1 %r156 to %ptr
	%r160 = ptrtoint %ptr %r155 to %word
	%r159 = icmp ne %word %r160, 0
	br i1 %r159, label %L430, label %L420
L430:
	br label %L420
L420:
	%r161 = load %ptr, %ptr* %t16
	%r162 = load %ptr, %ptr* %t15
	%r163 = call %ptr @digit_value(%ptr %r162)
	%r164 = inttoptr %word 8 to %ptr
	%r165 = load %ptr, %ptr* %t14
	%r166 = call %ptr @digit_value(%ptr %r165)
	%r170 = ptrtoint %ptr %r166 to %word
	%r169 = ptrtoint %ptr %r164 to %word
	%r168 = shl %word %r170, %r169
	%r167 = inttoptr %word %r168 to %ptr
	%r174 = ptrtoint %ptr %r167 to %word
	%r173 = ptrtoint %ptr %r163 to %word
	%r172 = add %word %r174, %r173
	%r171 = inttoptr %word %r172 to %ptr
	%r175 = inttoptr %word 16 to %ptr
	%r176 = load %ptr, %ptr* %t13
	%r177 = call %ptr @digit_value(%ptr %r176)
	%r181 = ptrtoint %ptr %r177 to %word
	%r180 = ptrtoint %ptr %r175 to %word
	%r179 = shl %word %r181, %r180
	%r178 = inttoptr %word %r179 to %ptr
	%r185 = ptrtoint %ptr %r178 to %word
	%r184 = ptrtoint %ptr %r171 to %word
	%r183 = add %word %r185, %r184
	%r182 = inttoptr %word %r183 to %ptr
	%r186 = inttoptr %word 24 to %ptr
	%r187 = load %ptr, %ptr* %t12
	%r188 = call %ptr @digit_value(%ptr %r187)
	%r192 = ptrtoint %ptr %r188 to %word
	%r191 = ptrtoint %ptr %r186 to %word
	%r190 = shl %word %r192, %r191
	%r189 = inttoptr %word %r190 to %ptr
	%r196 = ptrtoint %ptr %r189 to %word
	%r195 = ptrtoint %ptr %r182 to %word
	%r194 = add %word %r196, %r195
	%r193 = inttoptr %word %r194 to %ptr
	store %ptr %r193, %ptr* %t11
	br label %L419
L418:
	%r197 = inttoptr %word 120 to %ptr
	%r198 = load %ptr, %ptr* %t1
	%r202 = ptrtoint %ptr %r198 to %word
	%r201 = ptrtoint %ptr %r197 to %word
	%r200 = icmp eq %word %r202, %r201
	%r199 = inttoptr i1 %r200 to %ptr
	%r204 = ptrtoint %ptr %r199 to %word
	%r203 = icmp ne %word %r204, 0
	br i1 %r203, label %L431, label %L432
L431:
	%r205 = inttoptr %word 0 to %ptr
	store %ptr %r205, %ptr* %t14
	%r206 = load %ptr, %ptr* %t2
	%r207 = call i32 @fgetc(%ptr %r206)
	%r208 = inttoptr %word %r207 to %ptr
	store %ptr %r208, %ptr* %t1
	%r209 = call %ptr @is_hexadecimal(%ptr %r208)
	%r211 = ptrtoint %ptr %r209 to %word
	%r210 = icmp ne %word %r211, 0
	br i1 %r210, label %L434, label %L435
L434:
	%r212 = load %ptr, %ptr* %t1
	%r213 = call %ptr @digit_value(%ptr %r212)
	store %ptr %r213, %ptr* %t14
	%r214 = load %ptr, %ptr* %t2
	%r215 = call i32 @fgetc(%ptr %r214)
	%r216 = inttoptr %word %r215 to %ptr
	store %ptr %r216, %ptr* %t1
	%r217 = call %ptr @is_hexadecimal(%ptr %r216)
	%r219 = ptrtoint %ptr %r217 to %word
	%r218 = icmp ne %word %r219, 0
	br i1 %r218, label %L437, label %L438
L437:
	%r220 = load %ptr, %ptr* %t1
	%r221 = call %ptr @digit_value(%ptr %r220)
	%r222 = inttoptr %word 16 to %ptr
	%r223 = load %ptr, %ptr* %t14
	%r227 = ptrtoint %ptr %r223 to %word
	%r226 = ptrtoint %ptr %r222 to %word
	%r225 = mul %word %r227, %r226
	%r224 = inttoptr %word %r225 to %ptr
	%r231 = ptrtoint %ptr %r224 to %word
	%r230 = ptrtoint %ptr %r221 to %word
	%r229 = add %word %r231, %r230
	%r228 = inttoptr %word %r229 to %ptr
	store %ptr %r228, %ptr* %t14
	%r232 = load %ptr, %ptr* %t2
	%r233 = call i32 @fgetc(%ptr %r232)
	%r234 = inttoptr %word %r233 to %ptr
	store %ptr %r234, %ptr* %t1
	store %ptr %r234, %ptr* %t12
	br label %L439
L438:
	%r235 = getelementptr [9 x i8], [9 x i8]* @str440, %word 0, %word 0
	%r237 = call i32 (%ptr, ...) @printf(%ptr %r235)
	%r238 = inttoptr %word %r237 to %ptr
	%r239 = getelementptr [25 x i8], [25 x i8]* @str441, %word 0, %word 0
	%r241 = call i32 (%ptr, ...) @printf(%ptr %r239)
	%r242 = inttoptr %word %r241 to %ptr
	%r243 = getelementptr [2 x i8], [2 x i8]* @str442, %word 0, %word 0
	%r245 = call i32 (%ptr, ...) @printf(%ptr %r243)
	%r246 = inttoptr %word %r245 to %ptr
	%r247 = call %ptr @die()
	store %ptr %r247, %ptr* %t12
	br label %L439
L439:
	%r248 = load %ptr, %ptr* %t12
	store %ptr %r248, %ptr* %t13
	br label %L436
L435:
	%r249 = inttoptr %word 0 to %ptr
	store %ptr %r249, %ptr* %t13
	br label %L436
L436:
	%r250 = load %ptr, %ptr* %t13
	%r251 = load %ptr, %ptr* %t1
	%r252 = load %ptr, %ptr* %t2
	%ffi-cast253 = ptrtoint %ptr %r251 to i32
	%r254 = call i32 @ungetc(i32 %ffi-cast253, %ptr %r252)
	%r255 = inttoptr %word %r254 to %ptr
	%r256 = load %ptr, %ptr* %t14
	store %ptr %r256, %ptr* %t15
	br label %L433
L432:
	%r257 = inttoptr %word 1 to %ptr
	store %ptr %r257, %ptr* %t13
	%r258 = load %ptr, %ptr* %t1
	%r259 = inttoptr %word 48 to %ptr
	%r263 = ptrtoint %ptr %r259 to %word
	%r262 = ptrtoint %ptr %r258 to %word
	%r261 = icmp sle %word %r263, %r262
	%r260 = inttoptr i1 %r261 to %ptr
	store %ptr %r260, %ptr* %t13
	%r264 = inttoptr %word 0 to %ptr
	%r268 = ptrtoint %ptr %r264 to %word
	%r267 = ptrtoint %ptr %r260 to %word
	%r266 = icmp eq %word %r268, %r267
	%r265 = inttoptr i1 %r266 to %ptr
	%r270 = ptrtoint %ptr %r265 to %word
	%r269 = icmp ne %word %r270, 0
	br i1 %r269, label %L446, label %L447
L447:
	%r271 = inttoptr %word 55 to %ptr
	%r272 = load %ptr, %ptr* %t1
	%r276 = ptrtoint %ptr %r272 to %word
	%r275 = ptrtoint %ptr %r271 to %word
	%r274 = icmp sle %word %r276, %r275
	%r273 = inttoptr i1 %r274 to %ptr
	store %ptr %r273, %ptr* %t13
	%r277 = inttoptr %word 0 to %ptr
	%r281 = ptrtoint %ptr %r277 to %word
	%r280 = ptrtoint %ptr %r273 to %word
	%r279 = icmp eq %word %r281, %r280
	%r278 = inttoptr i1 %r279 to %ptr
	%r283 = ptrtoint %ptr %r278 to %word
	%r282 = icmp ne %word %r283, 0
	br i1 %r282, label %L446, label %L448
L448:
	br label %L446
L446:
	%r284 = load %ptr, %ptr* %t13
	%r286 = ptrtoint %ptr %r284 to %word
	%r285 = icmp ne %word %r286, 0
	br i1 %r285, label %L443, label %L444
L443:
	%r287 = load %ptr, %ptr* %t1
	%r288 = call %ptr @digit_value(%ptr %r287)
	store %ptr %r288, %ptr* %t13
	%r289 = load %ptr, %ptr* %t2
	%r290 = call i32 @fgetc(%ptr %r289)
	%r291 = inttoptr %word %r290 to %ptr
	store %ptr %r291, %ptr* %t1
	%r292 = call %ptr @is_octal(%ptr %r291)
	%r294 = ptrtoint %ptr %r292 to %word
	%r293 = icmp ne %word %r294, 0
	br i1 %r293, label %L449, label %L450
L449:
	%r295 = load %ptr, %ptr* %t1
	%r296 = call %ptr @digit_value(%ptr %r295)
	%r297 = inttoptr %word 8 to %ptr
	%r298 = load %ptr, %ptr* %t13
	%r302 = ptrtoint %ptr %r298 to %word
	%r301 = ptrtoint %ptr %r297 to %word
	%r300 = mul %word %r302, %r301
	%r299 = inttoptr %word %r300 to %ptr
	%r306 = ptrtoint %ptr %r299 to %word
	%r305 = ptrtoint %ptr %r296 to %word
	%r304 = add %word %r306, %r305
	%r303 = inttoptr %word %r304 to %ptr
	store %ptr %r303, %ptr* %t13
	%r307 = load %ptr, %ptr* %t2
	%r308 = call i32 @fgetc(%ptr %r307)
	%r309 = inttoptr %word %r308 to %ptr
	store %ptr %r309, %ptr* %t1
	%r310 = call %ptr @is_octal(%ptr %r309)
	%r312 = ptrtoint %ptr %r310 to %word
	%r311 = icmp ne %word %r312, 0
	br i1 %r311, label %L452, label %L453
L452:
	%r313 = load %ptr, %ptr* %t1
	%r314 = call %ptr @digit_value(%ptr %r313)
	%r315 = inttoptr %word 8 to %ptr
	%r316 = load %ptr, %ptr* %t13
	%r320 = ptrtoint %ptr %r316 to %word
	%r319 = ptrtoint %ptr %r315 to %word
	%r318 = mul %word %r320, %r319
	%r317 = inttoptr %word %r318 to %ptr
	%r324 = ptrtoint %ptr %r317 to %word
	%r323 = ptrtoint %ptr %r314 to %word
	%r322 = add %word %r324, %r323
	%r321 = inttoptr %word %r322 to %ptr
	store %ptr %r321, %ptr* %t13
	%r325 = load %ptr, %ptr* %t2
	%r326 = call i32 @fgetc(%ptr %r325)
	%r327 = inttoptr %word %r326 to %ptr
	store %ptr %r327, %ptr* %t1
	store %ptr %r327, %ptr* %t16
	br label %L454
L453:
	%r328 = getelementptr [9 x i8], [9 x i8]* @str455, %word 0, %word 0
	%r330 = call i32 (%ptr, ...) @printf(%ptr %r328)
	%r331 = inttoptr %word %r330 to %ptr
	%r332 = getelementptr [25 x i8], [25 x i8]* @str456, %word 0, %word 0
	%r334 = call i32 (%ptr, ...) @printf(%ptr %r332)
	%r335 = inttoptr %word %r334 to %ptr
	%r336 = getelementptr [2 x i8], [2 x i8]* @str457, %word 0, %word 0
	%r338 = call i32 (%ptr, ...) @printf(%ptr %r336)
	%r339 = inttoptr %word %r338 to %ptr
	%r340 = call %ptr @die()
	store %ptr %r340, %ptr* %t16
	br label %L454
L454:
	%r341 = load %ptr, %ptr* %t16
	store %ptr %r341, %ptr* %t12
	br label %L451
L450:
	%r342 = inttoptr %word 0 to %ptr
	store %ptr %r342, %ptr* %t12
	br label %L451
L451:
	%r343 = load %ptr, %ptr* %t12
	%r344 = load %ptr, %ptr* %t1
	%r345 = load %ptr, %ptr* %t2
	%ffi-cast346 = ptrtoint %ptr %r344 to i32
	%r347 = call i32 @ungetc(i32 %ffi-cast346, %ptr %r345)
	%r348 = inttoptr %word %r347 to %ptr
	%r349 = load %ptr, %ptr* %t13
	store %ptr %r349, %ptr* %t14
	br label %L445
L444:
	%r350 = inttoptr %word 0 to %ptr
	store %ptr %r350, %ptr* %t12
	%r351 = load %ptr, %ptr* %t1
	%r352 = call %ptr @is_alpha(%ptr %r351)
	store %ptr %r352, %ptr* %t12
	%r353 = inttoptr %word 0 to %ptr
	%r357 = ptrtoint %ptr %r353 to %word
	%r356 = ptrtoint %ptr %r352 to %word
	%r355 = icmp eq %word %r357, %r356
	%r354 = inttoptr i1 %r355 to %ptr
	%r359 = ptrtoint %ptr %r354 to %word
	%r358 = icmp ne %word %r359, 0
	br i1 %r358, label %L462, label %L461
L462:
	%r360 = load %ptr, %ptr* %t1
	%r361 = call %ptr @is_digit10(%ptr %r360)
	store %ptr %r361, %ptr* %t12
	%r362 = inttoptr %word 0 to %ptr
	%r366 = ptrtoint %ptr %r362 to %word
	%r365 = ptrtoint %ptr %r361 to %word
	%r364 = icmp eq %word %r366, %r365
	%r363 = inttoptr i1 %r364 to %ptr
	%r368 = ptrtoint %ptr %r363 to %word
	%r367 = icmp ne %word %r368, 0
	br i1 %r367, label %L463, label %L461
L463:
	br label %L461
L461:
	%r369 = load %ptr, %ptr* %t12
	%r371 = ptrtoint %ptr %r369 to %word
	%r370 = icmp ne %word %r371, 0
	br i1 %r370, label %L458, label %L459
L458:
	%r372 = getelementptr [30 x i8], [30 x i8]* @str464, %word 0, %word 0
	%r374 = load %ptr, %ptr* %t1
	%r375 = call %ptr @fatal1(%ptr %r372, %ptr %r374)
	store %ptr %r375, %ptr* %t13
	br label %L460
L459:
	%r376 = load %ptr, %ptr* %t1
	store %ptr %r376, %ptr* %t13
	br label %L460
L460:
	%r377 = load %ptr, %ptr* %t13
	store %ptr %r377, %ptr* %t14
	br label %L445
L445:
	%r378 = load %ptr, %ptr* %t14
	store %ptr %r378, %ptr* %t15
	br label %L433
L433:
	%r379 = load %ptr, %ptr* %t15
	store %ptr %r379, %ptr* %t11
	br label %L419
L419:
	%r380 = load %ptr, %ptr* %t11
	store %ptr %r380, %ptr* %t10
	br label %L416
L416:
	%r381 = load %ptr, %ptr* %t10
	store %ptr %r381, %ptr* %t9
	br label %L413
L413:
	%r382 = load %ptr, %ptr* %t9
	store %ptr %r382, %ptr* %t8
	br label %L410
L410:
	%r383 = load %ptr, %ptr* %t8
	store %ptr %r383, %ptr* %t7
	br label %L407
L407:
	%r384 = load %ptr, %ptr* %t7
	store %ptr %r384, %ptr* %t6
	br label %L404
L404:
	%r385 = load %ptr, %ptr* %t6
	store %ptr %r385, %ptr* %t5
	br label %L401
L401:
	%r386 = load %ptr, %ptr* %t5
	store %ptr %r386, %ptr* %t4
	br label %L398
L398:
	%r387 = load %ptr, %ptr* %t4
	store %ptr %r387, %ptr* %t3
	br label %L395
L394:
	%r388 = load %ptr, %ptr* %t1
	store %ptr %r388, %ptr* %t3
	br label %L395
L395:
	%r389 = load %ptr, %ptr* %t3
	ret %ptr %r389
}
@str485 = private unnamed_addr constant [2 x i8] c"1\00"
@str489 = private unnamed_addr constant [92 x i8] c"invalid number in source code, libc/strtoul failed for '%s' (printed without the sign here)\00"
define %ptr @read_number(%ptr %c, %ptr %stream) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %c, %ptr* %t1
	store %ptr %stream, %ptr* %t2
	%r1 = call %ptr @new_buffer()
	store %ptr %r1, %ptr* %t3
	%r2 = inttoptr %word 0 to %ptr
	store %ptr %r2, %ptr* %t4
	%r3 = inttoptr %word 10 to %ptr
	store %ptr %r3, %ptr* %t5
	%r4 = load %ptr, %ptr* %t1
	%r5 = inttoptr %word 45 to %ptr
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	%r11 = ptrtoint %ptr %r6 to %word
	%r10 = icmp ne %word %r11, 0
	br i1 %r10, label %L465, label %L466
L465:
	%r12 = inttoptr %word 1 to %ptr
	store %ptr %r12, %ptr* %t4
	store %ptr %r12, %ptr* %t6
	br label %L467
L466:
	%r13 = load %ptr, %ptr* %t3
	%r14 = load %ptr, %ptr* %t1
	%r15 = call %ptr @buffer_append(%ptr %r13, %ptr %r14)
	store %ptr %r15, %ptr* %t6
	br label %L467
L467:
	%r16 = load %ptr, %ptr* %t6
	br label %L469
L468:
	%r17 = load %ptr, %ptr* %t3
	%r18 = load %ptr, %ptr* %t1
	%r19 = call %ptr @buffer_append(%ptr %r17, %ptr %r18)
	br label %L469
L469:
	%r20 = load %ptr, %ptr* %t2
	%r21 = call i32 @fgetc(%ptr %r20)
	%r22 = inttoptr %word %r21 to %ptr
	store %ptr %r22, %ptr* %t1
	%r23 = call %ptr @is_digit10(%ptr %r22)
	%r25 = ptrtoint %ptr %r23 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L468, label %L470
L470:
	%r26 = inttoptr %word 1 to %ptr
	store %ptr %r26, %ptr* %t6
	%r27 = inttoptr %word 1 to %ptr
	store %ptr %r27, %ptr* %t7
	%r28 = load %ptr, %ptr* %t1
	%r29 = inttoptr %word 120 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	store %ptr %r30, %ptr* %t7
	%r34 = inttoptr %word 0 to %ptr
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = icmp eq %word %r38, %r37
	%r35 = inttoptr i1 %r36 to %ptr
	%r40 = ptrtoint %ptr %r35 to %word
	%r39 = icmp ne %word %r40, 0
	br i1 %r39, label %L472, label %L473
L473:
	%r41 = inttoptr %word 2 to %ptr
	%r42 = load %ptr, %ptr* %t3
	%r46 = bitcast %ptr %r42 to [0 x %ptr]*
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = getelementptr [0 x %ptr], [0 x %ptr]* %r46, %word 0, %word %r45
	%r43 = load %ptr, %ptr* %r44
	%r47 = inttoptr %word 1 to %ptr
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r43 to %word
	%r49 = icmp eq %word %r51, %r50
	%r48 = inttoptr i1 %r49 to %ptr
	store %ptr %r48, %ptr* %t7
	%r52 = inttoptr %word 0 to %ptr
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r48 to %word
	%r54 = icmp eq %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	%r58 = ptrtoint %ptr %r53 to %word
	%r57 = icmp ne %word %r58, 0
	br i1 %r57, label %L472, label %L474
L474:
	br label %L472
L472:
	%r59 = load %ptr, %ptr* %t7
	store %ptr %r59, %ptr* %t6
	%r60 = inttoptr %word 0 to %ptr
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = icmp eq %word %r64, %r63
	%r61 = inttoptr i1 %r62 to %ptr
	%r66 = ptrtoint %ptr %r61 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L471, label %L475
L475:
	%r67 = inttoptr %word 16 to %ptr
	store %ptr %r67, %ptr* %t5
	%r68 = load %ptr, %ptr* %t3
	%r69 = load %ptr, %ptr* %t1
	%r70 = call %ptr @buffer_append(%ptr %r68, %ptr %r69)
	br label %L477
L476:
	%r71 = load %ptr, %ptr* %t3
	%r72 = load %ptr, %ptr* %t1
	%r73 = call %ptr @buffer_append(%ptr %r71, %ptr %r72)
	br label %L477
L477:
	%r74 = load %ptr, %ptr* %t2
	%r75 = call i32 @fgetc(%ptr %r74)
	%r76 = inttoptr %word %r75 to %ptr
	store %ptr %r76, %ptr* %t1
	%r77 = call %ptr @is_digit16(%ptr %r76)
	%r79 = ptrtoint %ptr %r77 to %word
	%r78 = icmp ne %word %r79, 0
	br i1 %r78, label %L476, label %L478
L478:
	store %ptr %r77, %ptr* %t6
	%r80 = inttoptr %word 0 to %ptr
	%r84 = ptrtoint %ptr %r80 to %word
	%r83 = ptrtoint %ptr %r77 to %word
	%r82 = icmp eq %word %r84, %r83
	%r81 = inttoptr i1 %r82 to %ptr
	%r86 = ptrtoint %ptr %r81 to %word
	%r85 = icmp ne %word %r86, 0
	br i1 %r85, label %L471, label %L479
L479:
	br label %L471
L471:
	%r87 = load %ptr, %ptr* %t6
	%r88 = load %ptr, %ptr* %t1
	%r89 = load %ptr, %ptr* %t2
	%ffi-cast90 = ptrtoint %ptr %r88 to i32
	%r91 = call i32 @ungetc(i32 %ffi-cast90, %ptr %r89)
	%r92 = inttoptr %word %r91 to %ptr
	%r93 = load %ptr, %ptr* %t3
	%r94 = call %ptr @buffer_contents(%ptr %r93)
	store %ptr %r94, %ptr* %t6
	%r95 = load %ptr, %ptr* %t6
	store %ptr %r95, %ptr* %t7
	%r96 = load %ptr, %ptr* %t6
	%r98 = getelementptr %ptr, %ptr* %t7, %word 0
	%r97 = bitcast %ptr* %r98 to %ptr
	%r99 = load %ptr, %ptr* %t5
	%ffi-cast100 = ptrtoint %ptr %r99 to i32
	%r101 = call i32 @strtoul(%ptr %r96, %ptr %r97, i32 %ffi-cast100)
	%r102 = inttoptr %word %r101 to %ptr
	store %ptr %r102, %ptr* %t8
	%r103 = inttoptr %word 1 to %ptr
	store %ptr %r103, %ptr* %t9
	%r104 = inttoptr %word 1 to %ptr
	store %ptr %r104, %ptr* %t10
	%r105 = load %ptr, %ptr* %t8
	%r106 = inttoptr %word -1 to %ptr
	%r110 = ptrtoint %ptr %r106 to %word
	%r109 = ptrtoint %ptr %r105 to %word
	%r108 = icmp eq %word %r110, %r109
	%r107 = inttoptr i1 %r108 to %ptr
	store %ptr %r107, %ptr* %t10
	%r111 = inttoptr %word 0 to %ptr
	%r115 = ptrtoint %ptr %r111 to %word
	%r114 = ptrtoint %ptr %r107 to %word
	%r113 = icmp eq %word %r115, %r114
	%r112 = inttoptr i1 %r113 to %ptr
	%r117 = ptrtoint %ptr %r112 to %word
	%r116 = icmp ne %word %r117, 0
	br i1 %r116, label %L481, label %L482
L482:
	%r118 = inttoptr %word 0 to %ptr
	store %ptr %r118, %ptr* %t11
	%r119 = load %ptr, %ptr* %t4
	%r123 = ptrtoint %ptr %r119 to %word
	%r122 = icmp eq %word %r123, 0
	%r121 = zext i1 %r122 to %word
	%r120 = inttoptr %word %r121 to %ptr
	store %ptr %r120, %ptr* %t11
	%r124 = inttoptr %word 0 to %ptr
	%r128 = ptrtoint %ptr %r124 to %word
	%r127 = ptrtoint %ptr %r120 to %word
	%r126 = icmp eq %word %r128, %r127
	%r125 = inttoptr i1 %r126 to %ptr
	%r130 = ptrtoint %ptr %r125 to %word
	%r129 = icmp ne %word %r130, 0
	br i1 %r129, label %L484, label %L483
L484:
	%r131 = load %ptr, %ptr* %t6
	%r132 = getelementptr [2 x i8], [2 x i8]* @str485, %word 0, %word 0
	%r134 = call i32 @strcmp(%ptr %r131, %ptr %r132)
	%r135 = inttoptr %word %r134 to %ptr
	%r136 = inttoptr %word 0 to %ptr
	%r140 = ptrtoint %ptr %r136 to %word
	%r139 = ptrtoint %ptr %r135 to %word
	%r138 = icmp eq %word %r140, %r139
	%r137 = inttoptr i1 %r138 to %ptr
	%r144 = ptrtoint %ptr %r137 to %word
	%r143 = icmp eq %word %r144, 0
	%r142 = zext i1 %r143 to %word
	%r141 = inttoptr %word %r142 to %ptr
	store %ptr %r141, %ptr* %t11
	%r145 = inttoptr %word 0 to %ptr
	%r149 = ptrtoint %ptr %r145 to %word
	%r148 = ptrtoint %ptr %r141 to %word
	%r147 = icmp eq %word %r149, %r148
	%r146 = inttoptr i1 %r147 to %ptr
	%r151 = ptrtoint %ptr %r146 to %word
	%r150 = icmp ne %word %r151, 0
	br i1 %r150, label %L486, label %L483
L486:
	br label %L483
L483:
	%r152 = load %ptr, %ptr* %t11
	store %ptr %r152, %ptr* %t10
	%r153 = inttoptr %word 0 to %ptr
	%r157 = ptrtoint %ptr %r153 to %word
	%r156 = ptrtoint %ptr %r152 to %word
	%r155 = icmp eq %word %r157, %r156
	%r154 = inttoptr i1 %r155 to %ptr
	%r159 = ptrtoint %ptr %r154 to %word
	%r158 = icmp ne %word %r159, 0
	br i1 %r158, label %L481, label %L487
L487:
	br label %L481
L481:
	%r160 = load %ptr, %ptr* %t10
	store %ptr %r160, %ptr* %t9
	%r161 = inttoptr %word 0 to %ptr
	%r165 = ptrtoint %ptr %r161 to %word
	%r164 = ptrtoint %ptr %r160 to %word
	%r163 = icmp eq %word %r165, %r164
	%r162 = inttoptr i1 %r163 to %ptr
	%r167 = ptrtoint %ptr %r162 to %word
	%r166 = icmp ne %word %r167, 0
	br i1 %r166, label %L480, label %L488
L488:
	%r168 = getelementptr [92 x i8], [92 x i8]* @str489, %word 0, %word 0
	%r170 = load %ptr, %ptr* %t6
	%r171 = call %ptr @fatal1(%ptr %r168, %ptr %r170)
	store %ptr %r171, %ptr* %t9
	%r172 = inttoptr %word 0 to %ptr
	%r176 = ptrtoint %ptr %r172 to %word
	%r175 = ptrtoint %ptr %r171 to %word
	%r174 = icmp eq %word %r176, %r175
	%r173 = inttoptr i1 %r174 to %ptr
	%r178 = ptrtoint %ptr %r173 to %word
	%r177 = icmp ne %word %r178, 0
	br i1 %r177, label %L480, label %L490
L490:
	br label %L480
L480:
	%r179 = load %ptr, %ptr* %t9
	%r180 = load %ptr, %ptr* %t3
	%r181 = call %ptr @buffer_delete(%ptr %r180)
	%r182 = inttoptr %word 1 to %ptr
	%r183 = inttoptr %word 1 to %ptr
	%r184 = load %ptr, %ptr* %t4
	%r186 = ptrtoint %ptr %r184 to %word
	%r185 = icmp ne %word %r186, 0
	br i1 %r185, label %L491, label %L492
L491:
	%r187 = load %ptr, %ptr* %t8
	%r190 = ptrtoint %ptr %r187 to %word
	%r189 = sub nsw %word 0, %r190
	%r188 = inttoptr %word %r189 to %ptr
	store %ptr %r188, %ptr* %t9
	br label %L493
L492:
	%r191 = load %ptr, %ptr* %t8
	store %ptr %r191, %ptr* %t9
	br label %L493
L493:
	%r192 = load %ptr, %ptr* %t9
	%r196 = ptrtoint %ptr %r192 to %word
	%r195 = ptrtoint %ptr %r183 to %word
	%r194 = shl %word %r196, %r195
	%r193 = inttoptr %word %r194 to %ptr
	%r200 = ptrtoint %ptr %r193 to %word
	%r199 = ptrtoint %ptr %r182 to %word
	%r198 = add %word %r200, %r199
	%r197 = inttoptr %word %r198 to %ptr
	ret %ptr %r197
}
define %ptr @read_symbol(%ptr %c, %ptr %stream) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %c, %ptr* %t1
	store %ptr %stream, %ptr* %t2
	%r1 = call %ptr @new_buffer()
	store %ptr %r1, %ptr* %t3
	br label %L495
L494:
	%r2 = load %ptr, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @buffer_append(%ptr %r2, %ptr %r3)
	%r5 = load %ptr, %ptr* %t2
	%r6 = call i32 @fgetc(%ptr %r5)
	%r7 = inttoptr %word %r6 to %ptr
	store %ptr %r7, %ptr* %t1
	br label %L495
L495:
	%r8 = inttoptr %word 0 to %ptr
	store %ptr %r8, %ptr* %t4
	%r9 = load %ptr, %ptr* %t1
	%r10 = call %ptr @is_letter(%ptr %r9)
	store %ptr %r10, %ptr* %t4
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L498, label %L497
L498:
	%r18 = load %ptr, %ptr* %t1
	%r19 = call %ptr @is_digit10(%ptr %r18)
	store %ptr %r19, %ptr* %t4
	%r20 = inttoptr %word 0 to %ptr
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = icmp eq %word %r24, %r23
	%r21 = inttoptr i1 %r22 to %ptr
	%r26 = ptrtoint %ptr %r21 to %word
	%r25 = icmp ne %word %r26, 0
	br i1 %r25, label %L499, label %L497
L499:
	br label %L497
L497:
	%r27 = load %ptr, %ptr* %t4
	%r29 = ptrtoint %ptr %r27 to %word
	%r28 = icmp ne %word %r29, 0
	br i1 %r28, label %L494, label %L496
L496:
	%r30 = load %ptr, %ptr* %t1
	%r31 = load %ptr, %ptr* %t2
	%ffi-cast32 = ptrtoint %ptr %r30 to i32
	%r33 = call i32 @ungetc(i32 %ffi-cast32, %ptr %r31)
	%r34 = inttoptr %word %r33 to %ptr
	%r35 = load %ptr, %ptr* %t3
	%r36 = call %ptr @buffer_contents(%ptr %r35)
	%r37 = call %ptr @intern(%ptr %r36)
	store %ptr %r37, %ptr* %t4
	%r38 = load %ptr, %ptr* %t3
	%r39 = call %ptr @buffer_delete(%ptr %r38)
	%r40 = load %ptr, %ptr* %t4
	ret %ptr %r40
}
@str505 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str506 = private unnamed_addr constant [28 x i8] c"unterminated string literal\00"
@str507 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @read_string(%ptr %c, %ptr %stream) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %c, %ptr* %t1
	store %ptr %stream, %ptr* %t2
	%r1 = call %ptr @new_buffer()
	store %ptr %r1, %ptr* %t3
	br label %L501
L500:
	%r2 = load %ptr, %ptr* %t1
	%r3 = load %ptr, %ptr* %t2
	%r4 = call %ptr @read_char(%ptr %r2, %ptr %r3)
	store %ptr %r4, %ptr* %t1
	%r5 = inttoptr %word 1 to %ptr
	store %ptr %r5, %ptr* %t4
	%r6 = load %ptr, %ptr* %t1
	%r7 = inttoptr %word -1 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	store %ptr %r8, %ptr* %t4
	%r12 = inttoptr %word 0 to %ptr
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = ptrtoint %ptr %r8 to %word
	%r14 = icmp eq %word %r16, %r15
	%r13 = inttoptr i1 %r14 to %ptr
	%r18 = ptrtoint %ptr %r13 to %word
	%r17 = icmp ne %word %r18, 0
	br i1 %r17, label %L503, label %L504
L504:
	%r19 = getelementptr [9 x i8], [9 x i8]* @str505, %word 0, %word 0
	%r21 = call i32 (%ptr, ...) @printf(%ptr %r19)
	%r22 = inttoptr %word %r21 to %ptr
	%r23 = getelementptr [28 x i8], [28 x i8]* @str506, %word 0, %word 0
	%r25 = call i32 (%ptr, ...) @printf(%ptr %r23)
	%r26 = inttoptr %word %r25 to %ptr
	%r27 = getelementptr [2 x i8], [2 x i8]* @str507, %word 0, %word 0
	%r29 = call i32 (%ptr, ...) @printf(%ptr %r27)
	%r30 = inttoptr %word %r29 to %ptr
	%r31 = call %ptr @die()
	store %ptr %r31, %ptr* %t4
	%r32 = inttoptr %word 0 to %ptr
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = icmp eq %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	%r38 = ptrtoint %ptr %r33 to %word
	%r37 = icmp ne %word %r38, 0
	br i1 %r37, label %L503, label %L508
L508:
	br label %L503
L503:
	%r39 = load %ptr, %ptr* %t4
	%r40 = load %ptr, %ptr* %t3
	%r41 = load %ptr, %ptr* %t1
	%r42 = call %ptr @buffer_append(%ptr %r40, %ptr %r41)
	br label %L501
L501:
	%r43 = load %ptr, %ptr* %t2
	%r44 = call i32 @fgetc(%ptr %r43)
	%r45 = inttoptr %word %r44 to %ptr
	store %ptr %r45, %ptr* %t1
	%r46 = inttoptr %word 34 to %ptr
	%r50 = ptrtoint %ptr %r46 to %word
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = icmp ne %word %r50, %r49
	%r47 = inttoptr i1 %r48 to %ptr
	%r52 = ptrtoint %ptr %r47 to %word
	%r51 = icmp ne %word %r52, 0
	br i1 %r51, label %L500, label %L502
L502:
	%r53 = load %ptr, %ptr* %t3
	%r54 = call %ptr @buffer_contents(%ptr %r53)
	%r55 = call %ptr @"new-<string>-from-cstring"(%ptr %r54)
	store %ptr %r55, %ptr* %t4
	%r56 = load %ptr, %ptr* %t3
	%r57 = call %ptr @buffer_delete(%ptr %r56)
	%r58 = load %ptr, %ptr* %t4
	ret %ptr %r58
}
@str521 = private unnamed_addr constant [50 x i8] c"missing closing '%c' delimiter while reading list\00"
define %ptr @read_list(%ptr %delim, %ptr %stream) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %delim, %ptr* %t1
	store %ptr %stream, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = call %ptr @"new-<pair>"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	store %ptr %r5, %ptr* %t5
	%r7 = getelementptr %ptr, %ptr* %t3, %word 0
	%r6 = bitcast %ptr* %r7 to %ptr
	%r8 = call %ptr @"gc/push-root"(%ptr %r6)
	%r10 = getelementptr %ptr, %ptr* %t5, %word 0
	%r9 = bitcast %ptr* %r10 to %ptr
	%r11 = call %ptr @"gc/push-root"(%ptr %r9)
	br label %L510
L509:
	%r12 = load %ptr, %ptr* %t5
	%r13 = inttoptr %word 0 to %ptr
	%r14 = call %ptr @"new-<pair>"(%ptr %r12, %ptr %r13)
	store %ptr %r14, %ptr* %t5
	%r15 = load %ptr, %ptr* %t5
	%r16 = inttoptr %word 1 to %ptr
	%r17 = load %ptr, %ptr* %t4
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	store %ptr %r15, %ptr* %r19
	%r18 = bitcast %ptr %r15 to %ptr
	store %ptr %r18, %ptr* %t4
	br label %L510
L510:
	%r22 = inttoptr %word 1 to %ptr
	store %ptr %r22, %ptr* %t6
	%r23 = load %ptr, %ptr* %t2
	%r24 = call %ptr @"k/read"(%ptr %r23)
	store %ptr %r24, %ptr* %t5
	%r25 = load %ptr, %ptr* @"k/+done+"
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = icmp ne %word %r29, %r28
	%r26 = inttoptr i1 %r27 to %ptr
	store %ptr %r26, %ptr* %t6
	%r30 = inttoptr %word 0 to %ptr
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r26 to %word
	%r32 = icmp eq %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	%r36 = ptrtoint %ptr %r31 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L512, label %L513
L513:
	%r37 = load %ptr, %ptr* %t5
	%r38 = load %ptr, %ptr* @"symbol/dot"
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = icmp ne %word %r42, %r41
	%r39 = inttoptr i1 %r40 to %ptr
	store %ptr %r39, %ptr* %t6
	%r43 = inttoptr %word 0 to %ptr
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = ptrtoint %ptr %r39 to %word
	%r45 = icmp eq %word %r47, %r46
	%r44 = inttoptr i1 %r45 to %ptr
	%r49 = ptrtoint %ptr %r44 to %word
	%r48 = icmp ne %word %r49, 0
	br i1 %r48, label %L512, label %L514
L514:
	br label %L512
L512:
	%r50 = load %ptr, %ptr* %t6
	%r52 = ptrtoint %ptr %r50 to %word
	%r51 = icmp ne %word %r52, 0
	br i1 %r51, label %L509, label %L511
L511:
	%r53 = inttoptr %word 1 to %ptr
	store %ptr %r53, %ptr* %t6
	%r54 = load %ptr, %ptr* %t5
	%r55 = load %ptr, %ptr* @"symbol/dot"
	%r59 = ptrtoint %ptr %r55 to %word
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = icmp eq %word %r59, %r58
	%r56 = inttoptr i1 %r57 to %ptr
	store %ptr %r56, %ptr* %t6
	%r60 = inttoptr %word 0 to %ptr
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r56 to %word
	%r62 = icmp eq %word %r64, %r63
	%r61 = inttoptr i1 %r62 to %ptr
	%r66 = ptrtoint %ptr %r61 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L515, label %L516
L516:
	%r67 = load %ptr, %ptr* %t2
	%r68 = call %ptr @"k/read"(%ptr %r67)
	%r69 = inttoptr %word 1 to %ptr
	%r70 = load %ptr, %ptr* %t4
	%r74 = bitcast %ptr %r70 to [0 x %ptr]*
	%r73 = ptrtoint %ptr %r69 to %word
	%r72 = getelementptr [0 x %ptr], [0 x %ptr]* %r74, %word 0, %word %r73
	store %ptr %r68, %ptr* %r72
	%r71 = bitcast %ptr %r68 to %ptr
	store %ptr %r71, %ptr* %t6
	%r75 = inttoptr %word 0 to %ptr
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = ptrtoint %ptr %r71 to %word
	%r77 = icmp eq %word %r79, %r78
	%r76 = inttoptr i1 %r77 to %ptr
	%r81 = ptrtoint %ptr %r76 to %word
	%r80 = icmp ne %word %r81, 0
	br i1 %r80, label %L515, label %L517
L517:
	br label %L515
L515:
	%r82 = load %ptr, %ptr* %t6
	store %ptr %r82, %ptr* %t6
	%r84 = getelementptr %ptr, %ptr* %t5, %word 0
	%r83 = bitcast %ptr* %r84 to %ptr
	%r85 = call %ptr @"gc/pop-root"(%ptr %r83)
	%r87 = getelementptr %ptr, %ptr* %t3, %word 0
	%r86 = bitcast %ptr* %r87 to %ptr
	%r88 = call %ptr @"gc/pop-root"(%ptr %r86)
	%r89 = load %ptr, %ptr* %t6
	%r90 = load %ptr, %ptr* %t2
	%r91 = call i32 @fgetc(%ptr %r90)
	%r92 = inttoptr %word %r91 to %ptr
	store %ptr %r92, %ptr* %t6
	%r93 = load %ptr, %ptr* %t6
	%r94 = load %ptr, %ptr* %t1
	%r98 = ptrtoint %ptr %r94 to %word
	%r97 = ptrtoint %ptr %r93 to %word
	%r96 = icmp eq %word %r98, %r97
	%r95 = inttoptr i1 %r96 to %ptr
	%r100 = ptrtoint %ptr %r95 to %word
	%r99 = icmp ne %word %r100, 0
	br i1 %r99, label %L518, label %L519
L518:
	%r101 = inttoptr %word 1 to %ptr
	%r102 = load %ptr, %ptr* %t3
	%r106 = bitcast %ptr %r102 to [0 x %ptr]*
	%r105 = ptrtoint %ptr %r101 to %word
	%r104 = getelementptr [0 x %ptr], [0 x %ptr]* %r106, %word 0, %word %r105
	%r103 = load %ptr, %ptr* %r104
	store %ptr %r103, %ptr* %t7
	br label %L520
L519:
	%r107 = getelementptr [50 x i8], [50 x i8]* @str521, %word 0, %word 0
	%r109 = load %ptr, %ptr* %t1
	%r110 = call %ptr @fatal1(%ptr %r107, %ptr %r109)
	store %ptr %r110, %ptr* %t7
	br label %L520
L520:
	%r111 = load %ptr, %ptr* %t7
	ret %ptr %r111
}
@str524 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str525 = private unnamed_addr constant [33 x i8] c"EOF while reading quoted literal\00"
@str526 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @read_quote(%ptr %prefix, %ptr %stream) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %prefix, %ptr* %t1
	store %ptr %stream, %ptr* %t2
	%r1 = load %ptr, %ptr* %t2
	%r2 = call %ptr @"k/read"(%ptr %r1)
	store %ptr %r2, %ptr* %t3
	%r3 = inttoptr %word 1 to %ptr
	store %ptr %r3, %ptr* %t4
	%r4 = load %ptr, %ptr* %t3
	%r5 = load %ptr, %ptr* @"k/+done+"
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	store %ptr %r6, %ptr* %t4
	%r10 = inttoptr %word 0 to %ptr
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = icmp eq %word %r14, %r13
	%r11 = inttoptr i1 %r12 to %ptr
	%r16 = ptrtoint %ptr %r11 to %word
	%r15 = icmp ne %word %r16, 0
	br i1 %r15, label %L522, label %L523
L523:
	%r17 = getelementptr [9 x i8], [9 x i8]* @str524, %word 0, %word 0
	%r19 = call i32 (%ptr, ...) @printf(%ptr %r17)
	%r20 = inttoptr %word %r19 to %ptr
	%r21 = getelementptr [33 x i8], [33 x i8]* @str525, %word 0, %word 0
	%r23 = call i32 (%ptr, ...) @printf(%ptr %r21)
	%r24 = inttoptr %word %r23 to %ptr
	%r25 = getelementptr [2 x i8], [2 x i8]* @str526, %word 0, %word 0
	%r27 = call i32 (%ptr, ...) @printf(%ptr %r25)
	%r28 = inttoptr %word %r27 to %ptr
	%r29 = call %ptr @die()
	store %ptr %r29, %ptr* %t4
	%r30 = inttoptr %word 0 to %ptr
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = icmp eq %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	%r36 = ptrtoint %ptr %r31 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L522, label %L527
L527:
	br label %L522
L522:
	%r37 = load %ptr, %ptr* %t4
	%r39 = getelementptr %ptr, %ptr* %t3, %word 0
	%r38 = bitcast %ptr* %r39 to %ptr
	%r40 = call %ptr @"gc/push-root"(%ptr %r38)
	%r41 = load %ptr, %ptr* %t3
	%r42 = inttoptr %word 0 to %ptr
	%r43 = call %ptr @"new-<pair>"(%ptr %r41, %ptr %r42)
	store %ptr %r43, %ptr* %t3
	%r44 = load %ptr, %ptr* %t1
	%r45 = load %ptr, %ptr* %t3
	%r46 = call %ptr @"new-<pair>"(%ptr %r44, %ptr %r45)
	store %ptr %r46, %ptr* %t3
	%r47 = load %ptr, %ptr* %t3
	store %ptr %r47, %ptr* %t4
	%r49 = getelementptr %ptr, %ptr* %t3, %word 0
	%r48 = bitcast %ptr* %r49 to %ptr
	%r50 = call %ptr @"gc/pop-root"(%ptr %r48)
	%r51 = load %ptr, %ptr* %t4
	ret %ptr %r51
}
@str531 = private unnamed_addr constant [3 x i8] c"()\00"
@str535 = private unnamed_addr constant [3 x i8] c"%d\00"
@str542 = private unnamed_addr constant [3 x i8] c"%s\00"
@str543 = private unnamed_addr constant [2 x i8] c"\22\00"
@str556 = private unnamed_addr constant [3 x i8] c"\5C\22\00"
@str560 = private unnamed_addr constant [3 x i8] c"\5C\5C\00"
@str561 = private unnamed_addr constant [3 x i8] c"%c\00"
@str562 = private unnamed_addr constant [6 x i8] c"\5C%03o\00"
@str563 = private unnamed_addr constant [2 x i8] c"\22\00"
@str567 = private unnamed_addr constant [3 x i8] c"%s\00"
@str571 = private unnamed_addr constant [2 x i8] c"(\00"
@str577 = private unnamed_addr constant [2 x i8] c" \00"
@str581 = private unnamed_addr constant [4 x i8] c" . \00"
@str583 = private unnamed_addr constant [2 x i8] c")\00"
@str587 = private unnamed_addr constant [7 x i8] c"Array(\00"
@str593 = private unnamed_addr constant [2 x i8] c" \00"
@str595 = private unnamed_addr constant [2 x i8] c")\00"
@str599 = private unnamed_addr constant [6 x i8] c"Expr<\00"
@str600 = private unnamed_addr constant [2 x i8] c">\00"
@str604 = private unnamed_addr constant [6 x i8] c"Form<\00"
@str605 = private unnamed_addr constant [2 x i8] c",\00"
@str606 = private unnamed_addr constant [2 x i8] c">\00"
@str610 = private unnamed_addr constant [7 x i8] c"Fixed<\00"
@str611 = private unnamed_addr constant [2 x i8] c">\00"
@str615 = private unnamed_addr constant [9 x i8] c"Subr<%s>\00"
@str621 = private unnamed_addr constant [2 x i8] c".\00"
@str622 = private unnamed_addr constant [2 x i8] c"+\00"
@str633 = private unnamed_addr constant [11 x i8] c"Env<%d,%d>\00"
@str634 = private unnamed_addr constant [6 x i8] c"Env<>\00"
@str638 = private unnamed_addr constant [10 x i8] c"Context<>\00"
@str639 = private unnamed_addr constant [10 x i8] c"<type:%d>\00"
define %ptr @do_print(%ptr %obj, %ptr %storing) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t10 = alloca %ptr
	%t9 = alloca %ptr
	%t12 = alloca %ptr
	%t11 = alloca %ptr
	%t13 = alloca %ptr
	%t14 = alloca %ptr
	%t15 = alloca %ptr
	%t17 = alloca %ptr
	%t16 = alloca %ptr
	%t18 = alloca %ptr
	%t19 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	store %ptr %storing, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"get/type"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 4 to %ptr
	%r5 = load %ptr, %ptr* %t3
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	%r11 = ptrtoint %ptr %r6 to %word
	%r10 = icmp ne %word %r11, 0
	br i1 %r10, label %L528, label %L529
L528:
	%r12 = getelementptr [3 x i8], [3 x i8]* @str531, %word 0, %word 0
	%r14 = call i32 (%ptr, ...) @printf(%ptr %r12)
	%r15 = inttoptr %word %r14 to %ptr
	store %ptr %r15, %ptr* %t4
	br label %L530
L529:
	%r16 = inttoptr %word 6 to %ptr
	%r17 = load %ptr, %ptr* %t3
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp eq %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	%r23 = ptrtoint %ptr %r18 to %word
	%r22 = icmp ne %word %r23, 0
	br i1 %r22, label %L532, label %L533
L532:
	%r24 = getelementptr [3 x i8], [3 x i8]* @str535, %word 0, %word 0
	%r26 = inttoptr %word 1 to %ptr
	%r27 = load %ptr, %ptr* %t1
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = ashr %word %r31, %r30
	%r28 = inttoptr %word %r29 to %ptr
	%r32 = call i32 (%ptr, ...) @printf(%ptr %r24, %ptr %r28)
	%r33 = inttoptr %word %r32 to %ptr
	store %ptr %r33, %ptr* %t5
	br label %L534
L533:
	%r34 = inttoptr %word 17 to %ptr
	%r35 = load %ptr, %ptr* %t3
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = icmp eq %word %r39, %r38
	%r36 = inttoptr i1 %r37 to %ptr
	%r41 = ptrtoint %ptr %r36 to %word
	%r40 = icmp ne %word %r41, 0
	br i1 %r40, label %L536, label %L537
L536:
	%r42 = load %ptr, %ptr* %t1
	store %ptr %r42, %ptr* %t7
	%r43 = inttoptr %word 0 to %ptr
	%r44 = inttoptr %word 1 to %ptr
	%r45 = load %ptr, %ptr* %t7
	%r49 = bitcast %ptr %r45 to [0 x %ptr]*
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = getelementptr [0 x %ptr], [0 x %ptr]* %r49, %word 0, %word %r48
	%r46 = load %ptr, %ptr* %r47
	store %ptr %r46, %ptr* %t7
	%r50 = load %ptr, %ptr* %t2
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = icmp eq %word %r54, 0
	%r52 = zext i1 %r53 to %word
	%r51 = inttoptr %word %r52 to %ptr
	%r56 = ptrtoint %ptr %r51 to %word
	%r55 = icmp ne %word %r56, 0
	br i1 %r55, label %L539, label %L540
L539:
	%r57 = getelementptr [3 x i8], [3 x i8]* @str542, %word 0, %word 0
	%r59 = load %ptr, %ptr* %t7
	%r60 = call i32 (%ptr, ...) @printf(%ptr %r57, %ptr %r59)
	%r61 = inttoptr %word %r60 to %ptr
	store %ptr %r61, %ptr* %t8
	br label %L541
L540:
	%r62 = inttoptr %word 0 to %ptr
	store %ptr %r62, %ptr* %t9
	%r63 = inttoptr %word 0 to %ptr
	store %ptr %r63, %ptr* %t10
	%r64 = getelementptr [2 x i8], [2 x i8]* @str543, %word 0, %word 0
	%r66 = call i32 (%ptr, ...) @printf(%ptr %r64)
	%r67 = inttoptr %word %r66 to %ptr
	br label %L545
L544:
	%r68 = inttoptr %word 1 to %ptr
	store %ptr %r68, %ptr* %t12
	%r69 = load %ptr, %ptr* %t10
	%r70 = inttoptr %word 32 to %ptr
	%r74 = ptrtoint %ptr %r70 to %word
	%r73 = ptrtoint %ptr %r69 to %word
	%r72 = icmp sle %word %r74, %r73
	%r71 = inttoptr i1 %r72 to %ptr
	store %ptr %r71, %ptr* %t12
	%r75 = inttoptr %word 0 to %ptr
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = ptrtoint %ptr %r71 to %word
	%r77 = icmp eq %word %r79, %r78
	%r76 = inttoptr i1 %r77 to %ptr
	%r81 = ptrtoint %ptr %r76 to %word
	%r80 = icmp ne %word %r81, 0
	br i1 %r80, label %L550, label %L551
L551:
	%r82 = inttoptr %word 126 to %ptr
	%r83 = load %ptr, %ptr* %t10
	%r87 = ptrtoint %ptr %r83 to %word
	%r86 = ptrtoint %ptr %r82 to %word
	%r85 = icmp sle %word %r87, %r86
	%r84 = inttoptr i1 %r85 to %ptr
	store %ptr %r84, %ptr* %t12
	%r88 = inttoptr %word 0 to %ptr
	%r92 = ptrtoint %ptr %r88 to %word
	%r91 = ptrtoint %ptr %r84 to %word
	%r90 = icmp eq %word %r92, %r91
	%r89 = inttoptr i1 %r90 to %ptr
	%r94 = ptrtoint %ptr %r89 to %word
	%r93 = icmp ne %word %r94, 0
	br i1 %r93, label %L550, label %L552
L552:
	br label %L550
L550:
	%r95 = load %ptr, %ptr* %t12
	%r97 = ptrtoint %ptr %r95 to %word
	%r96 = icmp ne %word %r97, 0
	br i1 %r96, label %L547, label %L548
L547:
	%r98 = inttoptr %word 34 to %ptr
	%r99 = load %ptr, %ptr* %t10
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = ptrtoint %ptr %r98 to %word
	%r101 = icmp eq %word %r103, %r102
	%r100 = inttoptr i1 %r101 to %ptr
	%r105 = ptrtoint %ptr %r100 to %word
	%r104 = icmp ne %word %r105, 0
	br i1 %r104, label %L553, label %L554
L553:
	%r106 = getelementptr [3 x i8], [3 x i8]* @str556, %word 0, %word 0
	%r108 = call i32 (%ptr, ...) @printf(%ptr %r106)
	%r109 = inttoptr %word %r108 to %ptr
	store %ptr %r109, %ptr* %t12
	br label %L555
L554:
	%r110 = inttoptr %word 92 to %ptr
	%r111 = load %ptr, %ptr* %t10
	%r115 = ptrtoint %ptr %r111 to %word
	%r114 = ptrtoint %ptr %r110 to %word
	%r113 = icmp eq %word %r115, %r114
	%r112 = inttoptr i1 %r113 to %ptr
	%r117 = ptrtoint %ptr %r112 to %word
	%r116 = icmp ne %word %r117, 0
	br i1 %r116, label %L557, label %L558
L557:
	%r118 = getelementptr [3 x i8], [3 x i8]* @str560, %word 0, %word 0
	%r120 = call i32 (%ptr, ...) @printf(%ptr %r118)
	%r121 = inttoptr %word %r120 to %ptr
	store %ptr %r121, %ptr* %t13
	br label %L559
L558:
	%r122 = getelementptr [3 x i8], [3 x i8]* @str561, %word 0, %word 0
	%r124 = load %ptr, %ptr* %t10
	%r125 = call i32 (%ptr, ...) @printf(%ptr %r122, %ptr %r124)
	%r126 = inttoptr %word %r125 to %ptr
	store %ptr %r126, %ptr* %t13
	br label %L559
L559:
	%r127 = load %ptr, %ptr* %t13
	store %ptr %r127, %ptr* %t12
	br label %L555
L555:
	%r128 = load %ptr, %ptr* %t12
	store %ptr %r128, %ptr* %t11
	br label %L549
L548:
	%r129 = getelementptr [6 x i8], [6 x i8]* @str562, %word 0, %word 0
	%r131 = load %ptr, %ptr* %t10
	%r132 = call i32 (%ptr, ...) @printf(%ptr %r129, %ptr %r131)
	%r133 = inttoptr %word %r132 to %ptr
	store %ptr %r133, %ptr* %t11
	br label %L549
L549:
	%r134 = load %ptr, %ptr* %t11
	%r135 = load %ptr, %ptr* %t9
	%r136 = inttoptr %word 1 to %ptr
	%r140 = ptrtoint %ptr %r136 to %word
	%r139 = ptrtoint %ptr %r135 to %word
	%r138 = add %word %r140, %r139
	%r137 = inttoptr %word %r138 to %ptr
	store %ptr %r137, %ptr* %t9
	br label %L545
L545:
	%r141 = load %ptr, %ptr* %t9
	%r142 = load %ptr, %ptr* %t7
	%r147 = bitcast %ptr %r142 to [0 x i8]*
	%r146 = ptrtoint %ptr %r141 to %word
	%r145 = getelementptr [0 x i8], [0 x i8]* %r147, %word 0, %word %r146
	%r144 = load i8, i8* %r145
	%r143 = inttoptr i8 %r144 to %ptr
	store %ptr %r143, %ptr* %t10
	%r149 = ptrtoint %ptr %r143 to %word
	%r148 = icmp ne %word %r149, 0
	br i1 %r148, label %L544, label %L546
L546:
	%r150 = getelementptr [2 x i8], [2 x i8]* @str563, %word 0, %word 0
	%r152 = call i32 (%ptr, ...) @printf(%ptr %r150)
	%r153 = inttoptr %word %r152 to %ptr
	store %ptr %r153, %ptr* %t8
	br label %L541
L541:
	%r154 = load %ptr, %ptr* %t8
	store %ptr %r154, %ptr* %t6
	br label %L538
L537:
	%r155 = inttoptr %word 18 to %ptr
	%r156 = load %ptr, %ptr* %t3
	%r160 = ptrtoint %ptr %r156 to %word
	%r159 = ptrtoint %ptr %r155 to %word
	%r158 = icmp eq %word %r160, %r159
	%r157 = inttoptr i1 %r158 to %ptr
	%r162 = ptrtoint %ptr %r157 to %word
	%r161 = icmp ne %word %r162, 0
	br i1 %r161, label %L564, label %L565
L564:
	%r163 = getelementptr [3 x i8], [3 x i8]* @str567, %word 0, %word 0
	%r165 = load %ptr, %ptr* %t1
	store %ptr %r165, %ptr* %t8
	%r166 = inttoptr %word 0 to %ptr
	%r167 = inttoptr %word 0 to %ptr
	%r168 = load %ptr, %ptr* %t8
	%r172 = bitcast %ptr %r168 to [0 x %ptr]*
	%r171 = ptrtoint %ptr %r167 to %word
	%r170 = getelementptr [0 x %ptr], [0 x %ptr]* %r172, %word 0, %word %r171
	%r169 = load %ptr, %ptr* %r170
	%r173 = call i32 (%ptr, ...) @printf(%ptr %r163, %ptr %r169)
	%r174 = inttoptr %word %r173 to %ptr
	store %ptr %r174, %ptr* %t7
	br label %L566
L565:
	%r175 = inttoptr %word 19 to %ptr
	%r176 = load %ptr, %ptr* %t3
	%r180 = ptrtoint %ptr %r176 to %word
	%r179 = ptrtoint %ptr %r175 to %word
	%r178 = icmp eq %word %r180, %r179
	%r177 = inttoptr i1 %r178 to %ptr
	%r182 = ptrtoint %ptr %r177 to %word
	%r181 = icmp ne %word %r182, 0
	br i1 %r181, label %L568, label %L569
L568:
	%r183 = getelementptr [2 x i8], [2 x i8]* @str571, %word 0, %word 0
	%r185 = call i32 (%ptr, ...) @printf(%ptr %r183)
	%r186 = inttoptr %word %r185 to %ptr
	br label %L573
L572:
	%r187 = inttoptr %word 0 to %ptr
	%r188 = load %ptr, %ptr* %t1
	%r192 = bitcast %ptr %r188 to [0 x %ptr]*
	%r191 = ptrtoint %ptr %r187 to %word
	%r190 = getelementptr [0 x %ptr], [0 x %ptr]* %r192, %word 0, %word %r191
	%r189 = load %ptr, %ptr* %r190
	%r193 = load %ptr, %ptr* %t2
	%r194 = call %ptr @do_print(%ptr %r189, %ptr %r193)
	%r195 = inttoptr %word 1 to %ptr
	store %ptr %r195, %ptr* %t10
	%r196 = inttoptr %word 1 to %ptr
	%r197 = load %ptr, %ptr* %t1
	%r201 = bitcast %ptr %r197 to [0 x %ptr]*
	%r200 = ptrtoint %ptr %r196 to %word
	%r199 = getelementptr [0 x %ptr], [0 x %ptr]* %r201, %word 0, %word %r200
	%r198 = load %ptr, %ptr* %r199
	store %ptr %r198, %ptr* %t1
	%r202 = call %ptr @"get/type"(%ptr %r198)
	%r203 = inttoptr %word 19 to %ptr
	%r207 = ptrtoint %ptr %r203 to %word
	%r206 = ptrtoint %ptr %r202 to %word
	%r205 = icmp eq %word %r207, %r206
	%r204 = inttoptr i1 %r205 to %ptr
	store %ptr %r204, %ptr* %t10
	%r208 = inttoptr %word 0 to %ptr
	%r212 = ptrtoint %ptr %r208 to %word
	%r211 = ptrtoint %ptr %r204 to %word
	%r210 = icmp eq %word %r212, %r211
	%r209 = inttoptr i1 %r210 to %ptr
	%r214 = ptrtoint %ptr %r209 to %word
	%r213 = icmp ne %word %r214, 0
	br i1 %r213, label %L575, label %L576
L576:
	%r215 = getelementptr [2 x i8], [2 x i8]* @str577, %word 0, %word 0
	%r217 = call i32 (%ptr, ...) @printf(%ptr %r215)
	%r218 = inttoptr %word %r217 to %ptr
	store %ptr %r218, %ptr* %t10
	%r219 = inttoptr %word 0 to %ptr
	%r223 = ptrtoint %ptr %r219 to %word
	%r222 = ptrtoint %ptr %r218 to %word
	%r221 = icmp eq %word %r223, %r222
	%r220 = inttoptr i1 %r221 to %ptr
	%r225 = ptrtoint %ptr %r220 to %word
	%r224 = icmp ne %word %r225, 0
	br i1 %r224, label %L575, label %L578
L578:
	br label %L575
L575:
	%r226 = load %ptr, %ptr* %t10
	br label %L573
L573:
	%r227 = load %ptr, %ptr* %t1
	%r228 = call %ptr @"get/type"(%ptr %r227)
	%r229 = inttoptr %word 19 to %ptr
	%r233 = ptrtoint %ptr %r229 to %word
	%r232 = ptrtoint %ptr %r228 to %word
	%r231 = icmp eq %word %r233, %r232
	%r230 = inttoptr i1 %r231 to %ptr
	%r235 = ptrtoint %ptr %r230 to %word
	%r234 = icmp ne %word %r235, 0
	br i1 %r234, label %L572, label %L574
L574:
	%r236 = inttoptr %word 1 to %ptr
	store %ptr %r236, %ptr* %t10
	%r237 = load %ptr, %ptr* %t1
	store %ptr %r237, %ptr* %t10
	%r238 = inttoptr %word 0 to %ptr
	%r242 = ptrtoint %ptr %r238 to %word
	%r241 = ptrtoint %ptr %r237 to %word
	%r240 = icmp eq %word %r242, %r241
	%r239 = inttoptr i1 %r240 to %ptr
	%r244 = ptrtoint %ptr %r239 to %word
	%r243 = icmp ne %word %r244, 0
	br i1 %r243, label %L579, label %L580
L580:
	%r245 = getelementptr [4 x i8], [4 x i8]* @str581, %word 0, %word 0
	%r247 = call i32 (%ptr, ...) @printf(%ptr %r245)
	%r248 = inttoptr %word %r247 to %ptr
	%r249 = load %ptr, %ptr* %t1
	%r250 = load %ptr, %ptr* %t2
	%r251 = call %ptr @do_print(%ptr %r249, %ptr %r250)
	store %ptr %r251, %ptr* %t10
	%r252 = inttoptr %word 0 to %ptr
	%r256 = ptrtoint %ptr %r252 to %word
	%r255 = ptrtoint %ptr %r251 to %word
	%r254 = icmp eq %word %r256, %r255
	%r253 = inttoptr i1 %r254 to %ptr
	%r258 = ptrtoint %ptr %r253 to %word
	%r257 = icmp ne %word %r258, 0
	br i1 %r257, label %L579, label %L582
L582:
	br label %L579
L579:
	%r259 = load %ptr, %ptr* %t10
	%r260 = getelementptr [2 x i8], [2 x i8]* @str583, %word 0, %word 0
	%r262 = call i32 (%ptr, ...) @printf(%ptr %r260)
	%r263 = inttoptr %word %r262 to %ptr
	store %ptr %r263, %ptr* %t8
	br label %L570
L569:
	%r264 = inttoptr %word 7 to %ptr
	%r265 = load %ptr, %ptr* %t3
	%r269 = ptrtoint %ptr %r265 to %word
	%r268 = ptrtoint %ptr %r264 to %word
	%r267 = icmp eq %word %r269, %r268
	%r266 = inttoptr i1 %r267 to %ptr
	%r271 = ptrtoint %ptr %r266 to %word
	%r270 = icmp ne %word %r271, 0
	br i1 %r270, label %L584, label %L585
L584:
	%r272 = load %ptr, %ptr* %t1
	%r273 = call %ptr @"k/array-length"(%ptr %r272)
	store %ptr %r273, %ptr* %t9
	%r274 = getelementptr [7 x i8], [7 x i8]* @str587, %word 0, %word 0
	%r276 = call i32 (%ptr, ...) @printf(%ptr %r274)
	%r277 = inttoptr %word %r276 to %ptr
	%r278 = inttoptr %word 0 to %ptr
	store %ptr %r278, %ptr* %t11
	%r279 = load %ptr, %ptr* %t9
	store %ptr %r279, %ptr* %t12
	br label %L589
L588:
	%r280 = inttoptr %word 1 to %ptr
	store %ptr %r280, %ptr* %t13
	%r281 = load %ptr, %ptr* %t11
	store %ptr %r281, %ptr* %t13
	%r282 = inttoptr %word 0 to %ptr
	%r286 = ptrtoint %ptr %r282 to %word
	%r285 = ptrtoint %ptr %r281 to %word
	%r284 = icmp eq %word %r286, %r285
	%r283 = inttoptr i1 %r284 to %ptr
	%r288 = ptrtoint %ptr %r283 to %word
	%r287 = icmp ne %word %r288, 0
	br i1 %r287, label %L591, label %L592
L592:
	%r289 = getelementptr [2 x i8], [2 x i8]* @str593, %word 0, %word 0
	%r291 = call i32 (%ptr, ...) @printf(%ptr %r289)
	%r292 = inttoptr %word %r291 to %ptr
	store %ptr %r292, %ptr* %t13
	%r293 = inttoptr %word 0 to %ptr
	%r297 = ptrtoint %ptr %r293 to %word
	%r296 = ptrtoint %ptr %r292 to %word
	%r295 = icmp eq %word %r297, %r296
	%r294 = inttoptr i1 %r295 to %ptr
	%r299 = ptrtoint %ptr %r294 to %word
	%r298 = icmp ne %word %r299, 0
	br i1 %r298, label %L591, label %L594
L594:
	br label %L591
L591:
	%r300 = load %ptr, %ptr* %t13
	%r301 = load %ptr, %ptr* %t1
	%r302 = load %ptr, %ptr* %t11
	%r303 = call %ptr @"k/array-at"(%ptr %r301, %ptr %r302)
	%r304 = load %ptr, %ptr* %t2
	%r305 = call %ptr @do_print(%ptr %r303, %ptr %r304)
	%r306 = inttoptr %word 1 to %ptr
	%r307 = load %ptr, %ptr* %t11
	%r311 = ptrtoint %ptr %r307 to %word
	%r310 = ptrtoint %ptr %r306 to %word
	%r309 = add %word %r311, %r310
	%r308 = inttoptr %word %r309 to %ptr
	store %ptr %r308, %ptr* %t11
	br label %L589
L589:
	%r312 = load %ptr, %ptr* %t12
	%r313 = load %ptr, %ptr* %t11
	%r317 = ptrtoint %ptr %r313 to %word
	%r316 = ptrtoint %ptr %r312 to %word
	%r315 = icmp slt %word %r317, %r316
	%r314 = inttoptr i1 %r315 to %ptr
	%r319 = ptrtoint %ptr %r314 to %word
	%r318 = icmp ne %word %r319, 0
	br i1 %r318, label %L588, label %L590
L590:
	%r320 = getelementptr [2 x i8], [2 x i8]* @str595, %word 0, %word 0
	%r322 = call i32 (%ptr, ...) @printf(%ptr %r320)
	%r323 = inttoptr %word %r322 to %ptr
	store %ptr %r323, %ptr* %t10
	br label %L586
L585:
	%r324 = inttoptr %word 8 to %ptr
	%r325 = load %ptr, %ptr* %t3
	%r329 = ptrtoint %ptr %r325 to %word
	%r328 = ptrtoint %ptr %r324 to %word
	%r327 = icmp eq %word %r329, %r328
	%r326 = inttoptr i1 %r327 to %ptr
	%r331 = ptrtoint %ptr %r326 to %word
	%r330 = icmp ne %word %r331, 0
	br i1 %r330, label %L596, label %L597
L596:
	%r332 = getelementptr [6 x i8], [6 x i8]* @str599, %word 0, %word 0
	%r334 = call i32 (%ptr, ...) @printf(%ptr %r332)
	%r335 = inttoptr %word %r334 to %ptr
	%r336 = load %ptr, %ptr* %t1
	store %ptr %r336, %ptr* %t12
	%r337 = inttoptr %word 0 to %ptr
	%r338 = inttoptr %word 1 to %ptr
	%r339 = load %ptr, %ptr* %t12
	%r343 = bitcast %ptr %r339 to [0 x %ptr]*
	%r342 = ptrtoint %ptr %r338 to %word
	%r341 = getelementptr [0 x %ptr], [0 x %ptr]* %r343, %word 0, %word %r342
	%r340 = load %ptr, %ptr* %r341
	%r344 = call %ptr @"k/cadr"(%ptr %r340)
	%r345 = load %ptr, %ptr* %t2
	%r346 = call %ptr @do_print(%ptr %r344, %ptr %r345)
	%r347 = getelementptr [2 x i8], [2 x i8]* @str600, %word 0, %word 0
	%r349 = call i32 (%ptr, ...) @printf(%ptr %r347)
	%r350 = inttoptr %word %r349 to %ptr
	store %ptr %r350, %ptr* %t9
	br label %L598
L597:
	%r351 = inttoptr %word 9 to %ptr
	%r352 = load %ptr, %ptr* %t3
	%r356 = ptrtoint %ptr %r352 to %word
	%r355 = ptrtoint %ptr %r351 to %word
	%r354 = icmp eq %word %r356, %r355
	%r353 = inttoptr i1 %r354 to %ptr
	%r358 = ptrtoint %ptr %r353 to %word
	%r357 = icmp ne %word %r358, 0
	br i1 %r357, label %L601, label %L602
L601:
	%r359 = getelementptr [6 x i8], [6 x i8]* @str604, %word 0, %word 0
	%r361 = call i32 (%ptr, ...) @printf(%ptr %r359)
	%r362 = inttoptr %word %r361 to %ptr
	%r363 = load %ptr, %ptr* %t1
	store %ptr %r363, %ptr* %t11
	%r364 = inttoptr %word 0 to %ptr
	%r365 = inttoptr %word 0 to %ptr
	%r366 = load %ptr, %ptr* %t11
	%r370 = bitcast %ptr %r366 to [0 x %ptr]*
	%r369 = ptrtoint %ptr %r365 to %word
	%r368 = getelementptr [0 x %ptr], [0 x %ptr]* %r370, %word 0, %word %r369
	%r367 = load %ptr, %ptr* %r368
	%r371 = load %ptr, %ptr* %t2
	%r372 = call %ptr @do_print(%ptr %r367, %ptr %r371)
	%r373 = getelementptr [2 x i8], [2 x i8]* @str605, %word 0, %word 0
	%r375 = call i32 (%ptr, ...) @printf(%ptr %r373)
	%r376 = inttoptr %word %r375 to %ptr
	%r377 = load %ptr, %ptr* %t1
	store %ptr %r377, %ptr* %t11
	%r378 = inttoptr %word 0 to %ptr
	%r379 = inttoptr %word 1 to %ptr
	%r380 = load %ptr, %ptr* %t11
	%r384 = bitcast %ptr %r380 to [0 x %ptr]*
	%r383 = ptrtoint %ptr %r379 to %word
	%r382 = getelementptr [0 x %ptr], [0 x %ptr]* %r384, %word 0, %word %r383
	%r381 = load %ptr, %ptr* %r382
	%r385 = load %ptr, %ptr* %t2
	%r386 = call %ptr @do_print(%ptr %r381, %ptr %r385)
	%r387 = getelementptr [2 x i8], [2 x i8]* @str606, %word 0, %word 0
	%r389 = call i32 (%ptr, ...) @printf(%ptr %r387)
	%r390 = inttoptr %word %r389 to %ptr
	store %ptr %r390, %ptr* %t12
	br label %L603
L602:
	%r391 = inttoptr %word 10 to %ptr
	%r392 = load %ptr, %ptr* %t3
	%r396 = ptrtoint %ptr %r392 to %word
	%r395 = ptrtoint %ptr %r391 to %word
	%r394 = icmp eq %word %r396, %r395
	%r393 = inttoptr i1 %r394 to %ptr
	%r398 = ptrtoint %ptr %r393 to %word
	%r397 = icmp ne %word %r398, 0
	br i1 %r397, label %L607, label %L608
L607:
	%r399 = getelementptr [7 x i8], [7 x i8]* @str610, %word 0, %word 0
	%r401 = call i32 (%ptr, ...) @printf(%ptr %r399)
	%r402 = inttoptr %word %r401 to %ptr
	%r403 = load %ptr, %ptr* %t1
	store %ptr %r403, %ptr* %t13
	%r404 = inttoptr %word 0 to %ptr
	%r405 = inttoptr %word 0 to %ptr
	%r406 = load %ptr, %ptr* %t13
	%r410 = bitcast %ptr %r406 to [0 x %ptr]*
	%r409 = ptrtoint %ptr %r405 to %word
	%r408 = getelementptr [0 x %ptr], [0 x %ptr]* %r410, %word 0, %word %r409
	%r407 = load %ptr, %ptr* %r408
	%r411 = load %ptr, %ptr* %t2
	%r412 = call %ptr @do_print(%ptr %r407, %ptr %r411)
	%r413 = getelementptr [2 x i8], [2 x i8]* @str611, %word 0, %word 0
	%r415 = call i32 (%ptr, ...) @printf(%ptr %r413)
	%r416 = inttoptr %word %r415 to %ptr
	store %ptr %r416, %ptr* %t11
	br label %L609
L608:
	%r417 = inttoptr %word 11 to %ptr
	%r418 = load %ptr, %ptr* %t3
	%r422 = ptrtoint %ptr %r418 to %word
	%r421 = ptrtoint %ptr %r417 to %word
	%r420 = icmp eq %word %r422, %r421
	%r419 = inttoptr i1 %r420 to %ptr
	%r424 = ptrtoint %ptr %r419 to %word
	%r423 = icmp ne %word %r424, 0
	br i1 %r423, label %L612, label %L613
L612:
	%r425 = getelementptr [9 x i8], [9 x i8]* @str615, %word 0, %word 0
	%r427 = load %ptr, %ptr* %t1
	store %ptr %r427, %ptr* %t14
	%r428 = inttoptr %word 0 to %ptr
	%r429 = inttoptr %word 0 to %ptr
	%r430 = load %ptr, %ptr* %t14
	%r434 = bitcast %ptr %r430 to [0 x %ptr]*
	%r433 = ptrtoint %ptr %r429 to %word
	%r432 = getelementptr [0 x %ptr], [0 x %ptr]* %r434, %word 0, %word %r433
	%r431 = load %ptr, %ptr* %r432
	%r435 = call i32 (%ptr, ...) @printf(%ptr %r425, %ptr %r431)
	%r436 = inttoptr %word %r435 to %ptr
	store %ptr %r436, %ptr* %t13
	br label %L614
L613:
	%r437 = inttoptr %word 12 to %ptr
	%r438 = load %ptr, %ptr* %t3
	%r442 = ptrtoint %ptr %r438 to %word
	%r441 = ptrtoint %ptr %r437 to %word
	%r440 = icmp eq %word %r442, %r441
	%r439 = inttoptr i1 %r440 to %ptr
	%r444 = ptrtoint %ptr %r439 to %word
	%r443 = icmp ne %word %r444, 0
	br i1 %r443, label %L616, label %L617
L616:
	%r445 = load %ptr, %ptr* %t1
	store %ptr %r445, %ptr* %t15
	%r446 = inttoptr %word 0 to %ptr
	%r447 = inttoptr %word 2 to %ptr
	%r448 = load %ptr, %ptr* %t15
	%r452 = bitcast %ptr %r448 to [0 x %ptr]*
	%r451 = ptrtoint %ptr %r447 to %word
	%r450 = getelementptr [0 x %ptr], [0 x %ptr]* %r452, %word 0, %word %r451
	%r449 = load %ptr, %ptr* %r450
	store %ptr %r449, %ptr* %t15
	%r453 = load %ptr, %ptr* %t1
	store %ptr %r453, %ptr* %t16
	%r454 = inttoptr %word 0 to %ptr
	%r455 = inttoptr %word 0 to %ptr
	%r456 = load %ptr, %ptr* %t16
	%r460 = bitcast %ptr %r456 to [0 x %ptr]*
	%r459 = ptrtoint %ptr %r455 to %word
	%r458 = getelementptr [0 x %ptr], [0 x %ptr]* %r460, %word 0, %word %r459
	%r457 = load %ptr, %ptr* %r458
	%r461 = load %ptr, %ptr* %t2
	%r462 = call %ptr @do_print(%ptr %r457, %ptr %r461)
	%r463 = inttoptr %word 1 to %ptr
	store %ptr %r463, %ptr* %t16
	%r464 = load %ptr, %ptr* %t15
	store %ptr %r464, %ptr* %t16
	%r465 = inttoptr %word 0 to %ptr
	%r469 = ptrtoint %ptr %r465 to %word
	%r468 = ptrtoint %ptr %r464 to %word
	%r467 = icmp eq %word %r469, %r468
	%r466 = inttoptr i1 %r467 to %ptr
	%r471 = ptrtoint %ptr %r466 to %word
	%r470 = icmp ne %word %r471, 0
	br i1 %r470, label %L619, label %L620
L620:
	%r472 = getelementptr [2 x i8], [2 x i8]* @str621, %word 0, %word 0
	%r474 = call i32 (%ptr, ...) @printf(%ptr %r472)
	%r475 = inttoptr %word %r474 to %ptr
	%r476 = load %ptr, %ptr* %t15
	store %ptr %r476, %ptr* %t17
	%r477 = inttoptr %word 0 to %ptr
	%r478 = inttoptr %word 1 to %ptr
	%r479 = load %ptr, %ptr* %t17
	%r483 = bitcast %ptr %r479 to [0 x %ptr]*
	%r482 = ptrtoint %ptr %r478 to %word
	%r481 = getelementptr [0 x %ptr], [0 x %ptr]* %r483, %word 0, %word %r482
	%r480 = load %ptr, %ptr* %r481
	%r484 = load %ptr, %ptr* %t2
	%r485 = call %ptr @do_print(%ptr %r480, %ptr %r484)
	%r486 = getelementptr [2 x i8], [2 x i8]* @str622, %word 0, %word 0
	%r488 = call i32 (%ptr, ...) @printf(%ptr %r486)
	%r489 = inttoptr %word %r488 to %ptr
	%r490 = load %ptr, %ptr* %t1
	store %ptr %r490, %ptr* %t17
	%r491 = inttoptr %word 0 to %ptr
	%r492 = inttoptr %word 3 to %ptr
	%r493 = load %ptr, %ptr* %t17
	%r497 = bitcast %ptr %r493 to [0 x %ptr]*
	%r496 = ptrtoint %ptr %r492 to %word
	%r495 = getelementptr [0 x %ptr], [0 x %ptr]* %r497, %word 0, %word %r496
	%r494 = load %ptr, %ptr* %r495
	%r498 = load %ptr, %ptr* %t2
	%r499 = call %ptr @do_print(%ptr %r494, %ptr %r498)
	store %ptr %r499, %ptr* %t16
	%r500 = inttoptr %word 0 to %ptr
	%r504 = ptrtoint %ptr %r500 to %word
	%r503 = ptrtoint %ptr %r499 to %word
	%r502 = icmp eq %word %r504, %r503
	%r501 = inttoptr i1 %r502 to %ptr
	%r506 = ptrtoint %ptr %r501 to %word
	%r505 = icmp ne %word %r506, 0
	br i1 %r505, label %L619, label %L623
L623:
	br label %L619
L619:
	%r507 = load %ptr, %ptr* %t16
	store %ptr %r507, %ptr* %t14
	br label %L618
L617:
	%r508 = inttoptr %word 13 to %ptr
	%r509 = load %ptr, %ptr* %t3
	%r513 = ptrtoint %ptr %r509 to %word
	%r512 = ptrtoint %ptr %r508 to %word
	%r511 = icmp eq %word %r513, %r512
	%r510 = inttoptr i1 %r511 to %ptr
	%r515 = ptrtoint %ptr %r510 to %word
	%r514 = icmp ne %word %r515, 0
	br i1 %r514, label %L624, label %L625
L624:
	%r516 = load %ptr, %ptr* %t1
	store %ptr %r516, %ptr* %t16
	%r517 = inttoptr %word 0 to %ptr
	%r518 = inttoptr %word 1 to %ptr
	%r519 = load %ptr, %ptr* %t16
	%r523 = bitcast %ptr %r519 to [0 x %ptr]*
	%r522 = ptrtoint %ptr %r518 to %word
	%r521 = getelementptr [0 x %ptr], [0 x %ptr]* %r523, %word 0, %word %r522
	%r520 = load %ptr, %ptr* %r521
	store %ptr %r520, %ptr* %t16
	%r524 = load %ptr, %ptr* %t1
	store %ptr %r524, %ptr* %t17
	%r525 = inttoptr %word 0 to %ptr
	%r526 = inttoptr %word 3 to %ptr
	%r527 = load %ptr, %ptr* %t17
	%r531 = bitcast %ptr %r527 to [0 x %ptr]*
	%r530 = ptrtoint %ptr %r526 to %word
	%r529 = getelementptr [0 x %ptr], [0 x %ptr]* %r531, %word 0, %word %r530
	%r528 = load %ptr, %ptr* %r529
	store %ptr %r528, %ptr* %t17
	%r532 = inttoptr %word 1 to %ptr
	store %ptr %r532, %ptr* %t19
	%r533 = load %ptr, %ptr* %t16
	store %ptr %r533, %ptr* %t19
	%r534 = inttoptr %word 0 to %ptr
	%r538 = ptrtoint %ptr %r534 to %word
	%r537 = ptrtoint %ptr %r533 to %word
	%r536 = icmp eq %word %r538, %r537
	%r535 = inttoptr i1 %r536 to %ptr
	%r540 = ptrtoint %ptr %r535 to %word
	%r539 = icmp ne %word %r540, 0
	br i1 %r539, label %L630, label %L631
L631:
	%r541 = load %ptr, %ptr* %t17
	store %ptr %r541, %ptr* %t19
	%r542 = inttoptr %word 0 to %ptr
	%r546 = ptrtoint %ptr %r542 to %word
	%r545 = ptrtoint %ptr %r541 to %word
	%r544 = icmp eq %word %r546, %r545
	%r543 = inttoptr i1 %r544 to %ptr
	%r548 = ptrtoint %ptr %r543 to %word
	%r547 = icmp ne %word %r548, 0
	br i1 %r547, label %L630, label %L632
L632:
	br label %L630
L630:
	%r549 = load %ptr, %ptr* %t19
	%r551 = ptrtoint %ptr %r549 to %word
	%r550 = icmp ne %word %r551, 0
	br i1 %r550, label %L627, label %L628
L627:
	%r552 = getelementptr [11 x i8], [11 x i8]* @str633, %word 0, %word 0
	%r554 = inttoptr %word 1 to %ptr
	%r555 = load %ptr, %ptr* %t16
	%r559 = ptrtoint %ptr %r555 to %word
	%r558 = ptrtoint %ptr %r554 to %word
	%r557 = ashr %word %r559, %r558
	%r556 = inttoptr %word %r557 to %ptr
	%r560 = load %ptr, %ptr* %t17
	%r561 = call %ptr @"k/array-length"(%ptr %r560)
	%r562 = call i32 (%ptr, ...) @printf(%ptr %r552, %ptr %r556, %ptr %r561)
	%r563 = inttoptr %word %r562 to %ptr
	store %ptr %r563, %ptr* %t18
	br label %L629
L628:
	%r564 = getelementptr [6 x i8], [6 x i8]* @str634, %word 0, %word 0
	%r566 = call i32 (%ptr, ...) @printf(%ptr %r564)
	%r567 = inttoptr %word %r566 to %ptr
	store %ptr %r567, %ptr* %t18
	br label %L629
L629:
	%r568 = load %ptr, %ptr* %t18
	store %ptr %r568, %ptr* %t15
	br label %L626
L625:
	%r569 = inttoptr %word 14 to %ptr
	%r570 = load %ptr, %ptr* %t3
	%r574 = ptrtoint %ptr %r570 to %word
	%r573 = ptrtoint %ptr %r569 to %word
	%r572 = icmp eq %word %r574, %r573
	%r571 = inttoptr i1 %r572 to %ptr
	%r576 = ptrtoint %ptr %r571 to %word
	%r575 = icmp ne %word %r576, 0
	br i1 %r575, label %L635, label %L636
L635:
	%r577 = getelementptr [10 x i8], [10 x i8]* @str638, %word 0, %word 0
	%r579 = call i32 (%ptr, ...) @printf(%ptr %r577)
	%r580 = inttoptr %word %r579 to %ptr
	store %ptr %r580, %ptr* %t17
	br label %L637
L636:
	%r581 = getelementptr [10 x i8], [10 x i8]* @str639, %word 0, %word 0
	%r583 = load %ptr, %ptr* %t3
	%r584 = call i32 (%ptr, ...) @printf(%ptr %r581, %ptr %r583)
	%r585 = inttoptr %word %r584 to %ptr
	store %ptr %r585, %ptr* %t17
	br label %L637
L637:
	%r586 = load %ptr, %ptr* %t17
	store %ptr %r586, %ptr* %t15
	br label %L626
L626:
	%r587 = load %ptr, %ptr* %t15
	store %ptr %r587, %ptr* %t14
	br label %L618
L618:
	%r588 = load %ptr, %ptr* %t14
	store %ptr %r588, %ptr* %t13
	br label %L614
L614:
	%r589 = load %ptr, %ptr* %t13
	store %ptr %r589, %ptr* %t11
	br label %L609
L609:
	%r590 = load %ptr, %ptr* %t11
	store %ptr %r590, %ptr* %t12
	br label %L603
L603:
	%r591 = load %ptr, %ptr* %t12
	store %ptr %r591, %ptr* %t9
	br label %L598
L598:
	%r592 = load %ptr, %ptr* %t9
	store %ptr %r592, %ptr* %t10
	br label %L586
L586:
	%r593 = load %ptr, %ptr* %t10
	store %ptr %r593, %ptr* %t8
	br label %L570
L570:
	%r594 = load %ptr, %ptr* %t8
	store %ptr %r594, %ptr* %t7
	br label %L566
L566:
	%r595 = load %ptr, %ptr* %t7
	store %ptr %r595, %ptr* %t6
	br label %L538
L538:
	%r596 = load %ptr, %ptr* %t6
	store %ptr %r596, %ptr* %t5
	br label %L534
L534:
	%r597 = load %ptr, %ptr* %t5
	store %ptr %r597, %ptr* %t4
	br label %L530
L530:
	%r598 = load %ptr, %ptr* %t4
	ret %ptr %r598
}
@str640 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/println"(%ptr %obj) {
	%t1 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = inttoptr %word 0 to %ptr
	%r3 = call %ptr @do_print(%ptr %r1, %ptr %r2)
	%r4 = getelementptr [2 x i8], [2 x i8]* @str640, %word 0, %word 0
	%r6 = call i32 (%ptr, ...) @printf(%ptr %r4)
	%r7 = inttoptr %word %r6 to %ptr
	ret %ptr %r7
}
define %ptr @"k/dump"(%ptr %obj) {
	%t1 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = inttoptr %word 1 to %ptr
	%r3 = call %ptr @do_print(%ptr %r1, %ptr %r2)
	ret %ptr %r3
}
@str641 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/dumpln"(%ptr %obj) {
	%t1 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	%r1 = load %ptr, %ptr* %t1
	%r2 = inttoptr %word 1 to %ptr
	%r3 = call %ptr @do_print(%ptr %r1, %ptr %r2)
	%r4 = getelementptr [2 x i8], [2 x i8]* @str641, %word 0, %word 0
	%r6 = call i32 (%ptr, ...) @printf(%ptr %r4)
	%r7 = inttoptr %word %r6 to %ptr
	ret %ptr %r7
}
@str644 = private unnamed_addr constant [6 x i8] c"  E  \00"
@str645 = private unnamed_addr constant [2 x i8] c" \00"
@str674 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str675 = private unnamed_addr constant [16 x i8] c"symbol in eval?\00"
@str676 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/eval"(%ptr %exp, %ptr %ctx) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	%t12 = alloca %ptr
	%t13 = alloca %ptr
	store %ptr %exp, %ptr* %t1
	store %ptr %ctx, %ptr* %t2
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t3
	%r2 = load %ptr, %ptr* @"*arg/verbose*"
	%r3 = inttoptr %word 2 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp slt %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r4 to %word
	%r10 = icmp eq %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	%r14 = ptrtoint %ptr %r9 to %word
	%r13 = icmp ne %word %r14, 0
	br i1 %r13, label %L642, label %L643
L643:
	%r15 = getelementptr [6 x i8], [6 x i8]* @str644, %word 0, %word 0
	%r17 = call i32 (%ptr, ...) @printf(%ptr %r15)
	%r18 = inttoptr %word %r17 to %ptr
	%r19 = load %ptr, %ptr* %t1
	%r20 = call %ptr @"k/dump"(%ptr %r19)
	%r21 = getelementptr [2 x i8], [2 x i8]* @str645, %word 0, %word 0
	%r23 = call i32 (%ptr, ...) @printf(%ptr %r21)
	%r24 = inttoptr %word %r23 to %ptr
	%r25 = load %ptr, %ptr* %t2
	%r26 = call %ptr @"k/dumpln"(%ptr %r25)
	%r27 = call %ptr @"libc/flush-streams"()
	store %ptr %r27, %ptr* %t3
	%r28 = inttoptr %word 0 to %ptr
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = icmp eq %word %r32, %r31
	%r29 = inttoptr i1 %r30 to %ptr
	%r34 = ptrtoint %ptr %r29 to %word
	%r33 = icmp ne %word %r34, 0
	br i1 %r33, label %L642, label %L646
L646:
	br label %L642
L642:
	%r35 = load %ptr, %ptr* %t3
	%r36 = load %ptr, %ptr* %t1
	%r37 = call %ptr @"get/type"(%ptr %r36)
	store %ptr %r37, %ptr* %t3
	%r38 = inttoptr %word 4 to %ptr
	%r39 = load %ptr, %ptr* %t3
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = icmp eq %word %r43, %r42
	%r40 = inttoptr i1 %r41 to %ptr
	%r45 = ptrtoint %ptr %r40 to %word
	%r44 = icmp ne %word %r45, 0
	br i1 %r44, label %L647, label %L648
L647:
	%r46 = load %ptr, %ptr* %t1
	store %ptr %r46, %ptr* %t4
	br label %L649
L648:
	%r47 = inttoptr %word 6 to %ptr
	%r48 = load %ptr, %ptr* %t3
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = icmp eq %word %r52, %r51
	%r49 = inttoptr i1 %r50 to %ptr
	%r54 = ptrtoint %ptr %r49 to %word
	%r53 = icmp ne %word %r54, 0
	br i1 %r53, label %L650, label %L651
L650:
	%r55 = load %ptr, %ptr* %t1
	store %ptr %r55, %ptr* %t5
	br label %L652
L651:
	%r56 = inttoptr %word 17 to %ptr
	%r57 = load %ptr, %ptr* %t3
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = ptrtoint %ptr %r56 to %word
	%r59 = icmp eq %word %r61, %r60
	%r58 = inttoptr i1 %r59 to %ptr
	%r63 = ptrtoint %ptr %r58 to %word
	%r62 = icmp ne %word %r63, 0
	br i1 %r62, label %L653, label %L654
L653:
	%r64 = load %ptr, %ptr* %t1
	store %ptr %r64, %ptr* %t6
	br label %L655
L654:
	%r65 = inttoptr %word 12 to %ptr
	%r66 = load %ptr, %ptr* %t3
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = icmp eq %word %r70, %r69
	%r67 = inttoptr i1 %r68 to %ptr
	%r72 = ptrtoint %ptr %r67 to %word
	%r71 = icmp ne %word %r72, 0
	br i1 %r71, label %L656, label %L657
L656:
	%r73 = load %ptr, %ptr* %t1
	%r74 = call %ptr @"global-variable?"(%ptr %r73)
	%r76 = ptrtoint %ptr %r74 to %word
	%r75 = icmp ne %word %r76, 0
	br i1 %r75, label %L659, label %L660
L659:
	%r77 = load %ptr, %ptr* %t1
	store %ptr %r77, %ptr* %t9
	%r78 = inttoptr %word 0 to %ptr
	%r79 = inttoptr %word 1 to %ptr
	%r80 = load %ptr, %ptr* %t9
	%r84 = bitcast %ptr %r80 to [0 x %ptr]*
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = getelementptr [0 x %ptr], [0 x %ptr]* %r84, %word 0, %word %r83
	%r81 = load %ptr, %ptr* %r82
	store %ptr %r81, %ptr* %t8
	br label %L661
L660:
	%r85 = inttoptr %word 1 to %ptr
	%r86 = load %ptr, %ptr* %t1
	store %ptr %r86, %ptr* %t9
	%r87 = inttoptr %word 0 to %ptr
	%r88 = inttoptr %word 2 to %ptr
	%r89 = load %ptr, %ptr* %t9
	%r93 = bitcast %ptr %r89 to [0 x %ptr]*
	%r92 = ptrtoint %ptr %r88 to %word
	%r91 = getelementptr [0 x %ptr], [0 x %ptr]* %r93, %word 0, %word %r92
	%r90 = load %ptr, %ptr* %r91
	store %ptr %r90, %ptr* %t9
	%r94 = inttoptr %word 0 to %ptr
	%r95 = inttoptr %word 1 to %ptr
	%r96 = load %ptr, %ptr* %t9
	%r100 = bitcast %ptr %r96 to [0 x %ptr]*
	%r99 = ptrtoint %ptr %r95 to %word
	%r98 = getelementptr [0 x %ptr], [0 x %ptr]* %r100, %word 0, %word %r99
	%r97 = load %ptr, %ptr* %r98
	%r104 = ptrtoint %ptr %r97 to %word
	%r103 = ptrtoint %ptr %r85 to %word
	%r102 = ashr %word %r104, %r103
	%r101 = inttoptr %word %r102 to %ptr
	%r105 = inttoptr %word 1 to %ptr
	%r106 = load %ptr, %ptr* %t2
	store %ptr %r106, %ptr* %t9
	%r107 = inttoptr %word 0 to %ptr
	%r108 = inttoptr %word 1 to %ptr
	%r109 = load %ptr, %ptr* %t9
	%r113 = bitcast %ptr %r109 to [0 x %ptr]*
	%r112 = ptrtoint %ptr %r108 to %word
	%r111 = getelementptr [0 x %ptr], [0 x %ptr]* %r113, %word 0, %word %r112
	%r110 = load %ptr, %ptr* %r111
	store %ptr %r110, %ptr* %t9
	%r114 = inttoptr %word 0 to %ptr
	%r115 = inttoptr %word 1 to %ptr
	%r116 = load %ptr, %ptr* %t9
	%r120 = bitcast %ptr %r116 to [0 x %ptr]*
	%r119 = ptrtoint %ptr %r115 to %word
	%r118 = getelementptr [0 x %ptr], [0 x %ptr]* %r120, %word 0, %word %r119
	%r117 = load %ptr, %ptr* %r118
	%r124 = ptrtoint %ptr %r117 to %word
	%r123 = ptrtoint %ptr %r105 to %word
	%r122 = ashr %word %r124, %r123
	%r121 = inttoptr %word %r122 to %ptr
	%r128 = ptrtoint %ptr %r121 to %word
	%r127 = ptrtoint %ptr %r101 to %word
	%r126 = sub %word %r128, %r127
	%r125 = inttoptr %word %r126 to %ptr
	store %ptr %r125, %ptr* %t9
	br label %L663
L662:
	%r129 = load %ptr, %ptr* %t2
	store %ptr %r129, %ptr* %t10
	%r130 = inttoptr %word 0 to %ptr
	%r131 = inttoptr %word 0 to %ptr
	%r132 = load %ptr, %ptr* %t10
	%r136 = bitcast %ptr %r132 to [0 x %ptr]*
	%r135 = ptrtoint %ptr %r131 to %word
	%r134 = getelementptr [0 x %ptr], [0 x %ptr]* %r136, %word 0, %word %r135
	%r133 = load %ptr, %ptr* %r134
	store %ptr %r133, %ptr* %t2
	%r137 = inttoptr %word 1 to %ptr
	%r138 = load %ptr, %ptr* %t9
	%r142 = ptrtoint %ptr %r138 to %word
	%r141 = ptrtoint %ptr %r137 to %word
	%r140 = sub %word %r142, %r141
	%r139 = inttoptr %word %r140 to %ptr
	store %ptr %r139, %ptr* %t9
	br label %L663
L663:
	%r143 = load %ptr, %ptr* %t9
	%r144 = inttoptr %word 0 to %ptr
	%r148 = ptrtoint %ptr %r144 to %word
	%r147 = ptrtoint %ptr %r143 to %word
	%r146 = icmp slt %word %r148, %r147
	%r145 = inttoptr i1 %r146 to %ptr
	%r150 = ptrtoint %ptr %r145 to %word
	%r149 = icmp ne %word %r150, 0
	br i1 %r149, label %L662, label %L664
L664:
	%r151 = load %ptr, %ptr* %t2
	store %ptr %r151, %ptr* %t10
	%r152 = inttoptr %word 0 to %ptr
	%r153 = inttoptr %word 2 to %ptr
	%r154 = load %ptr, %ptr* %t10
	%r158 = bitcast %ptr %r154 to [0 x %ptr]*
	%r157 = ptrtoint %ptr %r153 to %word
	%r156 = getelementptr [0 x %ptr], [0 x %ptr]* %r158, %word 0, %word %r157
	%r155 = load %ptr, %ptr* %r156
	%r159 = inttoptr %word 1 to %ptr
	%r160 = load %ptr, %ptr* %t1
	store %ptr %r160, %ptr* %t10
	%r161 = inttoptr %word 0 to %ptr
	%r162 = inttoptr %word 3 to %ptr
	%r163 = load %ptr, %ptr* %t10
	%r167 = bitcast %ptr %r163 to [0 x %ptr]*
	%r166 = ptrtoint %ptr %r162 to %word
	%r165 = getelementptr [0 x %ptr], [0 x %ptr]* %r167, %word 0, %word %r166
	%r164 = load %ptr, %ptr* %r165
	%r171 = ptrtoint %ptr %r164 to %word
	%r170 = ptrtoint %ptr %r159 to %word
	%r169 = ashr %word %r171, %r170
	%r168 = inttoptr %word %r169 to %ptr
	%r172 = call %ptr @"k/array-at"(%ptr %r155, %ptr %r168)
	store %ptr %r172, %ptr* %t8
	br label %L661
L661:
	%r173 = load %ptr, %ptr* %t8
	store %ptr %r173, %ptr* %t7
	br label %L658
L657:
	%r174 = inttoptr %word 19 to %ptr
	%r175 = load %ptr, %ptr* %t3
	%r179 = ptrtoint %ptr %r175 to %word
	%r178 = ptrtoint %ptr %r174 to %word
	%r177 = icmp eq %word %r179, %r178
	%r176 = inttoptr i1 %r177 to %ptr
	%r181 = ptrtoint %ptr %r176 to %word
	%r180 = icmp ne %word %r181, 0
	br i1 %r180, label %L665, label %L666
L665:
	%r182 = inttoptr %word 0 to %ptr
	%r183 = load %ptr, %ptr* %t1
	%r187 = bitcast %ptr %r183 to [0 x %ptr]*
	%r186 = ptrtoint %ptr %r182 to %word
	%r185 = getelementptr [0 x %ptr], [0 x %ptr]* %r187, %word 0, %word %r186
	%r184 = load %ptr, %ptr* %r185
	store %ptr %r184, %ptr* %t9
	%r188 = inttoptr %word 0 to %ptr
	%r189 = load %ptr, %ptr* %t9
	%r190 = load %ptr, %ptr* %t2
	%r191 = call %ptr @"k/eval"(%ptr %r189, %ptr %r190)
	store %ptr %r191, %ptr* %t10
	%r193 = getelementptr %ptr, %ptr* %t10, %word 0
	%r192 = bitcast %ptr* %r193 to %ptr
	%r194 = call %ptr @"gc/push-root"(%ptr %r192)
	%r195 = inttoptr %word 0 to %ptr
	%r196 = load %ptr, %ptr* @"*backtrace-stack*"
	%r197 = load %ptr, %ptr* @"*backtrace-index*"
	%r198 = load %ptr, %ptr* %t1
	%r199 = call %ptr @"k/set-array-at"(%ptr %r196, %ptr %r197, %ptr %r198)
	%r200 = inttoptr %word 1 to %ptr
	%r201 = load %ptr, %ptr* @"*backtrace-index*"
	%r205 = ptrtoint %ptr %r201 to %word
	%r204 = ptrtoint %ptr %r200 to %word
	%r203 = add %word %r205, %r204
	%r202 = inttoptr %word %r203 to %ptr
	store %ptr %r202, %ptr* @"*backtrace-index*"
	%r206 = load %ptr, %ptr* %t10
	%r207 = call %ptr @"get/type"(%ptr %r206)
	%r208 = inttoptr %word 10 to %ptr
	%r212 = ptrtoint %ptr %r208 to %word
	%r211 = ptrtoint %ptr %r207 to %word
	%r210 = icmp eq %word %r212, %r211
	%r209 = inttoptr i1 %r210 to %ptr
	%r214 = ptrtoint %ptr %r209 to %word
	%r213 = icmp ne %word %r214, 0
	br i1 %r213, label %L668, label %L669
L668:
	%r215 = load %ptr, %ptr* %t10
	store %ptr %r215, %ptr* %t12
	%r216 = inttoptr %word 0 to %ptr
	%r217 = inttoptr %word 0 to %ptr
	%r218 = load %ptr, %ptr* %t12
	%r222 = bitcast %ptr %r218 to [0 x %ptr]*
	%r221 = ptrtoint %ptr %r217 to %word
	%r220 = getelementptr [0 x %ptr], [0 x %ptr]* %r222, %word 0, %word %r221
	%r219 = load %ptr, %ptr* %r220
	%r223 = inttoptr %word 1 to %ptr
	%r224 = load %ptr, %ptr* %t1
	%r228 = bitcast %ptr %r224 to [0 x %ptr]*
	%r227 = ptrtoint %ptr %r223 to %word
	%r226 = getelementptr [0 x %ptr], [0 x %ptr]* %r228, %word 0, %word %r227
	%r225 = load %ptr, %ptr* %r226
	%r229 = load %ptr, %ptr* %t2
	%r230 = call %ptr @"k/apply"(%ptr %r219, %ptr %r225, %ptr %r229)
	store %ptr %r230, %ptr* %t11
	br label %L670
L669:
	%r231 = inttoptr %word 1 to %ptr
	%r232 = load %ptr, %ptr* %t1
	%r236 = bitcast %ptr %r232 to [0 x %ptr]*
	%r235 = ptrtoint %ptr %r231 to %word
	%r234 = getelementptr [0 x %ptr], [0 x %ptr]* %r236, %word 0, %word %r235
	%r233 = load %ptr, %ptr* %r234
	%r237 = load %ptr, %ptr* %t2
	%r238 = call %ptr @evlist(%ptr %r233, %ptr %r237)
	store %ptr %r238, %ptr* %t12
	%r240 = getelementptr %ptr, %ptr* %t12, %word 0
	%r239 = bitcast %ptr* %r240 to %ptr
	%r241 = call %ptr @"gc/push-root"(%ptr %r239)
	%r242 = load %ptr, %ptr* %t10
	%r243 = load %ptr, %ptr* %t12
	%r244 = load %ptr, %ptr* %t2
	%r245 = call %ptr @"k/apply"(%ptr %r242, %ptr %r243, %ptr %r244)
	store %ptr %r245, %ptr* %t13
	%r247 = getelementptr %ptr, %ptr* %t12, %word 0
	%r246 = bitcast %ptr* %r247 to %ptr
	%r248 = call %ptr @"gc/pop-root"(%ptr %r246)
	%r249 = load %ptr, %ptr* %t13
	store %ptr %r249, %ptr* %t11
	br label %L670
L670:
	%r250 = load %ptr, %ptr* %t11
	store %ptr %r250, %ptr* %t10
	%r251 = inttoptr %word 1 to %ptr
	%r252 = load %ptr, %ptr* @"*backtrace-index*"
	%r256 = ptrtoint %ptr %r252 to %word
	%r255 = ptrtoint %ptr %r251 to %word
	%r254 = sub %word %r256, %r255
	%r253 = inttoptr %word %r254 to %ptr
	store %ptr %r253, %ptr* @"*backtrace-index*"
	%r257 = inttoptr %word 0 to %ptr
	%r258 = load %ptr, %ptr* %t10
	store %ptr %r258, %ptr* %t11
	%r260 = getelementptr %ptr, %ptr* %t10, %word 0
	%r259 = bitcast %ptr* %r260 to %ptr
	%r261 = call %ptr @"gc/pop-root"(%ptr %r259)
	%r262 = load %ptr, %ptr* %t11
	store %ptr %r262, %ptr* %t8
	br label %L667
L666:
	%r263 = inttoptr %word 18 to %ptr
	%r264 = load %ptr, %ptr* %t3
	%r268 = ptrtoint %ptr %r264 to %word
	%r267 = ptrtoint %ptr %r263 to %word
	%r266 = icmp eq %word %r268, %r267
	%r265 = inttoptr i1 %r266 to %ptr
	%r270 = ptrtoint %ptr %r265 to %word
	%r269 = icmp ne %word %r270, 0
	br i1 %r269, label %L671, label %L672
L671:
	%r271 = getelementptr [9 x i8], [9 x i8]* @str674, %word 0, %word 0
	%r273 = call i32 (%ptr, ...) @printf(%ptr %r271)
	%r274 = inttoptr %word %r273 to %ptr
	%r275 = getelementptr [16 x i8], [16 x i8]* @str675, %word 0, %word 0
	%r277 = call i32 (%ptr, ...) @printf(%ptr %r275)
	%r278 = inttoptr %word %r277 to %ptr
	%r279 = getelementptr [2 x i8], [2 x i8]* @str676, %word 0, %word 0
	%r281 = call i32 (%ptr, ...) @printf(%ptr %r279)
	%r282 = inttoptr %word %r281 to %ptr
	%r283 = call %ptr @die()
	store %ptr %r283, %ptr* %t9
	br label %L673
L672:
	%r284 = load %ptr, %ptr* @"var/*evaluators*"
	store %ptr %r284, %ptr* %t10
	%r285 = inttoptr %word 0 to %ptr
	%r286 = inttoptr %word 1 to %ptr
	%r287 = load %ptr, %ptr* %t10
	%r291 = bitcast %ptr %r287 to [0 x %ptr]*
	%r290 = ptrtoint %ptr %r286 to %word
	%r289 = getelementptr [0 x %ptr], [0 x %ptr]* %r291, %word 0, %word %r290
	%r288 = load %ptr, %ptr* %r289
	%r292 = load %ptr, %ptr* %t1
	%r293 = call %ptr @"get/type"(%ptr %r292)
	%r294 = call %ptr @"k/array-at"(%ptr %r288, %ptr %r293)
	store %ptr %r294, %ptr* %t10
	%r295 = inttoptr %word 1 to %ptr
	store %ptr %r295, %ptr* %t11
	%r296 = load %ptr, %ptr* %t10
	store %ptr %r296, %ptr* %t11
	%r297 = inttoptr %word 0 to %ptr
	%r301 = ptrtoint %ptr %r297 to %word
	%r300 = ptrtoint %ptr %r296 to %word
	%r299 = icmp eq %word %r301, %r300
	%r298 = inttoptr i1 %r299 to %ptr
	%r303 = ptrtoint %ptr %r298 to %word
	%r302 = icmp ne %word %r303, 0
	br i1 %r302, label %L677, label %L678
L678:
	%r304 = load %ptr, %ptr* %t1
	%r305 = inttoptr %word 0 to %ptr
	%r306 = call %ptr @"new-<pair>"(%ptr %r304, %ptr %r305)
	store %ptr %r306, %ptr* %t12
	%r308 = getelementptr %ptr, %ptr* %t12, %word 0
	%r307 = bitcast %ptr* %r308 to %ptr
	%r309 = call %ptr @"gc/push-root"(%ptr %r307)
	%r310 = load %ptr, %ptr* @"*backtrace-stack*"
	%r311 = load %ptr, %ptr* @"*backtrace-index*"
	%r312 = load %ptr, %ptr* %t1
	%r313 = call %ptr @"k/set-array-at"(%ptr %r310, %ptr %r311, %ptr %r312)
	%r314 = inttoptr %word 1 to %ptr
	%r315 = load %ptr, %ptr* @"*backtrace-index*"
	%r319 = ptrtoint %ptr %r315 to %word
	%r318 = ptrtoint %ptr %r314 to %word
	%r317 = add %word %r319, %r318
	%r316 = inttoptr %word %r317 to %ptr
	store %ptr %r316, %ptr* @"*backtrace-index*"
	%r320 = load %ptr, %ptr* %t10
	%r321 = load %ptr, %ptr* %t12
	%r322 = load %ptr, %ptr* %t2
	%r323 = call %ptr @"k/apply"(%ptr %r320, %ptr %r321, %ptr %r322)
	store %ptr %r323, %ptr* %t1
	%r324 = inttoptr %word 1 to %ptr
	%r325 = load %ptr, %ptr* @"*backtrace-index*"
	%r329 = ptrtoint %ptr %r325 to %word
	%r328 = ptrtoint %ptr %r324 to %word
	%r327 = sub %word %r329, %r328
	%r326 = inttoptr %word %r327 to %ptr
	store %ptr %r326, %ptr* @"*backtrace-index*"
	store %ptr %r326, %ptr* %t13
	%r331 = getelementptr %ptr, %ptr* %t12, %word 0
	%r330 = bitcast %ptr* %r331 to %ptr
	%r332 = call %ptr @"gc/pop-root"(%ptr %r330)
	%r333 = load %ptr, %ptr* %t13
	store %ptr %r333, %ptr* %t11
	%r334 = inttoptr %word 0 to %ptr
	%r338 = ptrtoint %ptr %r334 to %word
	%r337 = ptrtoint %ptr %r333 to %word
	%r336 = icmp eq %word %r338, %r337
	%r335 = inttoptr i1 %r336 to %ptr
	%r340 = ptrtoint %ptr %r335 to %word
	%r339 = icmp ne %word %r340, 0
	br i1 %r339, label %L677, label %L679
L679:
	br label %L677
L677:
	%r341 = load %ptr, %ptr* %t11
	%r342 = load %ptr, %ptr* %t1
	store %ptr %r342, %ptr* %t9
	br label %L673
L673:
	%r343 = load %ptr, %ptr* %t9
	store %ptr %r343, %ptr* %t8
	br label %L667
L667:
	%r344 = load %ptr, %ptr* %t8
	store %ptr %r344, %ptr* %t7
	br label %L658
L658:
	%r345 = load %ptr, %ptr* %t7
	store %ptr %r345, %ptr* %t6
	br label %L655
L655:
	%r346 = load %ptr, %ptr* %t6
	store %ptr %r346, %ptr* %t5
	br label %L652
L652:
	%r347 = load %ptr, %ptr* %t5
	store %ptr %r347, %ptr* %t4
	br label %L649
L649:
	%r348 = load %ptr, %ptr* %t4
	ret %ptr %r348
}
@str680 = private unnamed_addr constant [10 x i8] c"*globals*\00"
define %ptr @"new-<module>"() {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 15 to %ptr
	%r3 = inttoptr %word 8 to %ptr
	%r4 = call %ptr @"%new-object"(%ptr %r2, %ptr %r3)
	store %ptr %r4, %ptr* %t1
	%r6 = getelementptr %ptr, %ptr* %t1, %word 0
	%r5 = bitcast %ptr* %r6 to %ptr
	%r7 = call %ptr @"gc/push-root"(%ptr %r5)
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 0 to %ptr
	%r10 = inttoptr %word 0 to %ptr
	%r11 = call %ptr @"new-<env>"(%ptr %r8, %ptr %r9, %ptr %r10)
	store %ptr %r11, %ptr* %t2
	%r13 = getelementptr %ptr, %ptr* %t2, %word 0
	%r12 = bitcast %ptr* %r13 to %ptr
	%r14 = call %ptr @"gc/push-root"(%ptr %r12)
	%r15 = inttoptr %word 0 to %ptr
	%r16 = call %ptr @"new-<array>"(%ptr %r15)
	%r17 = inttoptr %word 0 to %ptr
	%r18 = load %ptr, %ptr* %t1
	%r22 = bitcast %ptr %r18 to [0 x %ptr]*
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = getelementptr [0 x %ptr], [0 x %ptr]* %r22, %word 0, %word %r21
	store %ptr %r16, %ptr* %r20
	%r19 = bitcast %ptr %r16 to %ptr
	%r23 = load %ptr, %ptr* %t2
	%r24 = getelementptr [10 x i8], [10 x i8]* @str680, %word 0, %word 0
	%r26 = load %ptr, %ptr* %t1
	%r27 = call %ptr @"intern*"(%ptr %r24, %ptr %r26)
	%r28 = load %ptr, %ptr* %t2
	%r29 = call %ptr @"k/env/define"(%ptr %r23, %ptr %r27, %ptr %r28)
	%r30 = inttoptr %word 1 to %ptr
	%r31 = load %ptr, %ptr* %t1
	%r35 = bitcast %ptr %r31 to [0 x %ptr]*
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = getelementptr [0 x %ptr], [0 x %ptr]* %r35, %word 0, %word %r34
	store %ptr %r29, %ptr* %r33
	%r32 = bitcast %ptr %r29 to %ptr
	%r36 = inttoptr %word 0 to %ptr
	%r37 = load %ptr, %ptr* %t1
	store %ptr %r37, %ptr* %t3
	%r39 = getelementptr %ptr, %ptr* %t2, %word 0
	%r38 = bitcast %ptr* %r39 to %ptr
	%r40 = call %ptr @"gc/pop-root"(%ptr %r38)
	%r41 = load %ptr, %ptr* %t3
	store %ptr %r41, %ptr* %t2
	%r43 = getelementptr %ptr, %ptr* %t1, %word 0
	%r42 = bitcast %ptr* %r43 to %ptr
	%r44 = call %ptr @"gc/pop-root"(%ptr %r42)
	%r45 = load %ptr, %ptr* %t2
	ret %ptr %r45
}
@str683 = private unnamed_addr constant [6 x i8] c"  A  \00"
@str684 = private unnamed_addr constant [2 x i8] c" \00"
@str685 = private unnamed_addr constant [2 x i8] c" \00"
@str692 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str693 = private unnamed_addr constant [23 x i8] c"too few arguments for \00"
@str694 = private unnamed_addr constant [3 x i8] c": \00"
@str695 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str702 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str703 = private unnamed_addr constant [24 x i8] c"too many arguments for \00"
@str704 = private unnamed_addr constant [3 x i8] c": \00"
@str705 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/apply-expr"(%ptr %fun, %ptr %arguments, %ptr %parent-ctx) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %fun, %ptr* %t1
	store %ptr %arguments, %ptr* %t2
	store %ptr %parent-ctx, %ptr* %t3
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t4
	%r2 = load %ptr, %ptr* @"*arg/verbose*"
	%r3 = inttoptr %word 2 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp slt %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	store %ptr %r4, %ptr* %t4
	%r8 = inttoptr %word 0 to %ptr
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = ptrtoint %ptr %r4 to %word
	%r10 = icmp eq %word %r12, %r11
	%r9 = inttoptr i1 %r10 to %ptr
	%r14 = ptrtoint %ptr %r9 to %word
	%r13 = icmp ne %word %r14, 0
	br i1 %r13, label %L681, label %L682
L682:
	%r15 = getelementptr [6 x i8], [6 x i8]* @str683, %word 0, %word 0
	%r17 = call i32 (%ptr, ...) @printf(%ptr %r15)
	%r18 = inttoptr %word %r17 to %ptr
	%r19 = load %ptr, %ptr* %t1
	%r20 = call %ptr @"k/dump"(%ptr %r19)
	%r21 = getelementptr [2 x i8], [2 x i8]* @str684, %word 0, %word 0
	%r23 = call i32 (%ptr, ...) @printf(%ptr %r21)
	%r24 = inttoptr %word %r23 to %ptr
	%r25 = load %ptr, %ptr* %t2
	%r26 = call %ptr @"k/dump"(%ptr %r25)
	%r27 = getelementptr [2 x i8], [2 x i8]* @str685, %word 0, %word 0
	%r29 = call i32 (%ptr, ...) @printf(%ptr %r27)
	%r30 = inttoptr %word %r29 to %ptr
	%r31 = load %ptr, %ptr* %t3
	%r32 = call %ptr @"k/dumpln"(%ptr %r31)
	%r33 = call %ptr @"libc/flush-streams"()
	store %ptr %r33, %ptr* %t4
	%r34 = inttoptr %word 0 to %ptr
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r33 to %word
	%r36 = icmp eq %word %r38, %r37
	%r35 = inttoptr i1 %r36 to %ptr
	%r40 = ptrtoint %ptr %r35 to %word
	%r39 = icmp ne %word %r40, 0
	br i1 %r39, label %L681, label %L686
L686:
	br label %L681
L681:
	%r41 = load %ptr, %ptr* %t4
	%r42 = load %ptr, %ptr* %t1
	store %ptr %r42, %ptr* %t4
	%r43 = inttoptr %word 0 to %ptr
	%r44 = inttoptr %word 1 to %ptr
	%r45 = load %ptr, %ptr* %t4
	%r49 = bitcast %ptr %r45 to [0 x %ptr]*
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = getelementptr [0 x %ptr], [0 x %ptr]* %r49, %word 0, %word %r48
	%r46 = load %ptr, %ptr* %r47
	store %ptr %r46, %ptr* %t4
	%r50 = load %ptr, %ptr* %t4
	%r51 = call %ptr @"k/car"(%ptr %r50)
	store %ptr %r51, %ptr* %t5
	%r52 = load %ptr, %ptr* %t4
	%r53 = call %ptr @"k/cadr"(%ptr %r52)
	store %ptr %r53, %ptr* %t6
	%r54 = load %ptr, %ptr* %t1
	store %ptr %r54, %ptr* %t7
	%r55 = inttoptr %word 0 to %ptr
	%r56 = inttoptr %word 2 to %ptr
	%r57 = load %ptr, %ptr* %t7
	%r61 = bitcast %ptr %r57 to [0 x %ptr]*
	%r60 = ptrtoint %ptr %r56 to %word
	%r59 = getelementptr [0 x %ptr], [0 x %ptr]* %r61, %word 0, %word %r60
	%r58 = load %ptr, %ptr* %r59
	%r62 = load %ptr, %ptr* %t3
	%r63 = load %ptr, %ptr* %t5
	%r64 = call %ptr @"new-<context>"(%ptr %r58, %ptr %r62, %ptr %r63)
	store %ptr %r64, %ptr* %t7
	%r66 = getelementptr %ptr, %ptr* %t7, %word 0
	%r65 = bitcast %ptr* %r66 to %ptr
	%r67 = call %ptr @"gc/push-root"(%ptr %r65)
	%r68 = load %ptr, %ptr* %t7
	store %ptr %r68, %ptr* %t8
	%r69 = inttoptr %word 0 to %ptr
	%r70 = inttoptr %word 2 to %ptr
	%r71 = load %ptr, %ptr* %t8
	%r75 = bitcast %ptr %r71 to [0 x %ptr]*
	%r74 = ptrtoint %ptr %r70 to %word
	%r73 = getelementptr [0 x %ptr], [0 x %ptr]* %r75, %word 0, %word %r74
	%r72 = load %ptr, %ptr* %r73
	store %ptr %r72, %ptr* %t8
	%r76 = load %ptr, %ptr* %t2
	store %ptr %r76, %ptr* %t9
	br label %L688
L687:
	%r77 = inttoptr %word 0 to %ptr
	store %ptr %r77, %ptr* %t10
	%r78 = load %ptr, %ptr* %t9
	%r79 = call %ptr @"get/type"(%ptr %r78)
	%r80 = inttoptr %word 19 to %ptr
	%r84 = ptrtoint %ptr %r80 to %word
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = icmp eq %word %r84, %r83
	%r81 = inttoptr i1 %r82 to %ptr
	store %ptr %r81, %ptr* %t10
	%r85 = inttoptr %word 0 to %ptr
	%r89 = ptrtoint %ptr %r85 to %word
	%r88 = ptrtoint %ptr %r81 to %word
	%r87 = icmp eq %word %r89, %r88
	%r86 = inttoptr i1 %r87 to %ptr
	%r91 = ptrtoint %ptr %r86 to %word
	%r90 = icmp ne %word %r91, 0
	br i1 %r90, label %L691, label %L690
L691:
	%r92 = getelementptr [9 x i8], [9 x i8]* @str692, %word 0, %word 0
	%r94 = call i32 (%ptr, ...) @printf(%ptr %r92)
	%r95 = inttoptr %word %r94 to %ptr
	%r96 = getelementptr [23 x i8], [23 x i8]* @str693, %word 0, %word 0
	%r98 = call i32 (%ptr, ...) @printf(%ptr %r96)
	%r99 = inttoptr %word %r98 to %ptr
	%r100 = load %ptr, %ptr* %t1
	%r101 = call %ptr @"k/print"(%ptr %r100)
	%r102 = getelementptr [3 x i8], [3 x i8]* @str694, %word 0, %word 0
	%r104 = call i32 (%ptr, ...) @printf(%ptr %r102)
	%r105 = inttoptr %word %r104 to %ptr
	%r106 = load %ptr, %ptr* %t2
	%r107 = call %ptr @"k/print"(%ptr %r106)
	%r108 = getelementptr [2 x i8], [2 x i8]* @str695, %word 0, %word 0
	%r110 = call i32 (%ptr, ...) @printf(%ptr %r108)
	%r111 = inttoptr %word %r110 to %ptr
	%r112 = call %ptr @die()
	store %ptr %r112, %ptr* %t10
	%r113 = inttoptr %word 0 to %ptr
	%r117 = ptrtoint %ptr %r113 to %word
	%r116 = ptrtoint %ptr %r112 to %word
	%r115 = icmp eq %word %r117, %r116
	%r114 = inttoptr i1 %r115 to %ptr
	%r119 = ptrtoint %ptr %r114 to %word
	%r118 = icmp ne %word %r119, 0
	br i1 %r118, label %L696, label %L690
L696:
	br label %L690
L690:
	%r120 = load %ptr, %ptr* %t10
	%r121 = load %ptr, %ptr* %t8
	%r122 = inttoptr %word 1 to %ptr
	%r123 = inttoptr %word 0 to %ptr
	%r124 = load %ptr, %ptr* %t6
	%r128 = bitcast %ptr %r124 to [0 x %ptr]*
	%r127 = ptrtoint %ptr %r123 to %word
	%r126 = getelementptr [0 x %ptr], [0 x %ptr]* %r128, %word 0, %word %r127
	%r125 = load %ptr, %ptr* %r126
	store %ptr %r125, %ptr* %t10
	%r129 = inttoptr %word 0 to %ptr
	%r130 = inttoptr %word 3 to %ptr
	%r131 = load %ptr, %ptr* %t10
	%r135 = bitcast %ptr %r131 to [0 x %ptr]*
	%r134 = ptrtoint %ptr %r130 to %word
	%r133 = getelementptr [0 x %ptr], [0 x %ptr]* %r135, %word 0, %word %r134
	%r132 = load %ptr, %ptr* %r133
	%r139 = ptrtoint %ptr %r132 to %word
	%r138 = ptrtoint %ptr %r122 to %word
	%r137 = ashr %word %r139, %r138
	%r136 = inttoptr %word %r137 to %ptr
	%r140 = inttoptr %word 0 to %ptr
	%r141 = load %ptr, %ptr* %t9
	%r145 = bitcast %ptr %r141 to [0 x %ptr]*
	%r144 = ptrtoint %ptr %r140 to %word
	%r143 = getelementptr [0 x %ptr], [0 x %ptr]* %r145, %word 0, %word %r144
	%r142 = load %ptr, %ptr* %r143
	%r146 = call %ptr @"k/set-array-at"(%ptr %r121, %ptr %r136, %ptr %r142)
	%r147 = inttoptr %word 1 to %ptr
	%r148 = load %ptr, %ptr* %t6
	%r152 = bitcast %ptr %r148 to [0 x %ptr]*
	%r151 = ptrtoint %ptr %r147 to %word
	%r150 = getelementptr [0 x %ptr], [0 x %ptr]* %r152, %word 0, %word %r151
	%r149 = load %ptr, %ptr* %r150
	store %ptr %r149, %ptr* %t6
	%r153 = inttoptr %word 1 to %ptr
	%r154 = load %ptr, %ptr* %t9
	%r158 = bitcast %ptr %r154 to [0 x %ptr]*
	%r157 = ptrtoint %ptr %r153 to %word
	%r156 = getelementptr [0 x %ptr], [0 x %ptr]* %r158, %word 0, %word %r157
	%r155 = load %ptr, %ptr* %r156
	store %ptr %r155, %ptr* %t9
	br label %L688
L688:
	%r159 = load %ptr, %ptr* %t6
	%r160 = call %ptr @"get/type"(%ptr %r159)
	%r161 = inttoptr %word 19 to %ptr
	%r165 = ptrtoint %ptr %r161 to %word
	%r164 = ptrtoint %ptr %r160 to %word
	%r163 = icmp eq %word %r165, %r164
	%r162 = inttoptr i1 %r163 to %ptr
	%r167 = ptrtoint %ptr %r162 to %word
	%r166 = icmp ne %word %r167, 0
	br i1 %r166, label %L687, label %L689
L689:
	%r168 = inttoptr %word 1 to %ptr
	store %ptr %r168, %ptr* %t10
	%r169 = load %ptr, %ptr* %t6
	%r170 = call %ptr @"get/type"(%ptr %r169)
	%r171 = inttoptr %word 12 to %ptr
	%r175 = ptrtoint %ptr %r171 to %word
	%r174 = ptrtoint %ptr %r170 to %word
	%r173 = icmp eq %word %r175, %r174
	%r172 = inttoptr i1 %r173 to %ptr
	store %ptr %r172, %ptr* %t10
	%r176 = inttoptr %word 0 to %ptr
	%r180 = ptrtoint %ptr %r176 to %word
	%r179 = ptrtoint %ptr %r172 to %word
	%r178 = icmp eq %word %r180, %r179
	%r177 = inttoptr i1 %r178 to %ptr
	%r182 = ptrtoint %ptr %r177 to %word
	%r181 = icmp ne %word %r182, 0
	br i1 %r181, label %L697, label %L698
L698:
	%r183 = load %ptr, %ptr* %t8
	%r184 = inttoptr %word 1 to %ptr
	%r185 = load %ptr, %ptr* %t6
	store %ptr %r185, %ptr* %t11
	%r186 = inttoptr %word 0 to %ptr
	%r187 = inttoptr %word 3 to %ptr
	%r188 = load %ptr, %ptr* %t11
	%r192 = bitcast %ptr %r188 to [0 x %ptr]*
	%r191 = ptrtoint %ptr %r187 to %word
	%r190 = getelementptr [0 x %ptr], [0 x %ptr]* %r192, %word 0, %word %r191
	%r189 = load %ptr, %ptr* %r190
	%r196 = ptrtoint %ptr %r189 to %word
	%r195 = ptrtoint %ptr %r184 to %word
	%r194 = ashr %word %r196, %r195
	%r193 = inttoptr %word %r194 to %ptr
	%r197 = load %ptr, %ptr* %t9
	%r198 = call %ptr @"k/set-array-at"(%ptr %r183, %ptr %r193, %ptr %r197)
	%r199 = inttoptr %word 0 to %ptr
	store %ptr %r199, %ptr* %t9
	store %ptr %r199, %ptr* %t10
	%r200 = inttoptr %word 0 to %ptr
	%r204 = ptrtoint %ptr %r200 to %word
	%r203 = ptrtoint %ptr %r199 to %word
	%r202 = icmp eq %word %r204, %r203
	%r201 = inttoptr i1 %r202 to %ptr
	%r206 = ptrtoint %ptr %r201 to %word
	%r205 = icmp ne %word %r206, 0
	br i1 %r205, label %L697, label %L699
L699:
	br label %L697
L697:
	%r207 = load %ptr, %ptr* %t10
	%r208 = inttoptr %word 1 to %ptr
	store %ptr %r208, %ptr* %t10
	%r209 = load %ptr, %ptr* %t9
	store %ptr %r209, %ptr* %t10
	%r210 = inttoptr %word 0 to %ptr
	%r214 = ptrtoint %ptr %r210 to %word
	%r213 = ptrtoint %ptr %r209 to %word
	%r212 = icmp eq %word %r214, %r213
	%r211 = inttoptr i1 %r212 to %ptr
	%r216 = ptrtoint %ptr %r211 to %word
	%r215 = icmp ne %word %r216, 0
	br i1 %r215, label %L700, label %L701
L701:
	%r217 = getelementptr [9 x i8], [9 x i8]* @str702, %word 0, %word 0
	%r219 = call i32 (%ptr, ...) @printf(%ptr %r217)
	%r220 = inttoptr %word %r219 to %ptr
	%r221 = getelementptr [24 x i8], [24 x i8]* @str703, %word 0, %word 0
	%r223 = call i32 (%ptr, ...) @printf(%ptr %r221)
	%r224 = inttoptr %word %r223 to %ptr
	%r225 = load %ptr, %ptr* %t1
	%r226 = call %ptr @"k/print"(%ptr %r225)
	%r227 = getelementptr [3 x i8], [3 x i8]* @str704, %word 0, %word 0
	%r229 = call i32 (%ptr, ...) @printf(%ptr %r227)
	%r230 = inttoptr %word %r229 to %ptr
	%r231 = load %ptr, %ptr* %t2
	%r232 = call %ptr @"k/print"(%ptr %r231)
	%r233 = getelementptr [2 x i8], [2 x i8]* @str705, %word 0, %word 0
	%r235 = call i32 (%ptr, ...) @printf(%ptr %r233)
	%r236 = inttoptr %word %r235 to %ptr
	%r237 = call %ptr @die()
	store %ptr %r237, %ptr* %t10
	%r238 = inttoptr %word 0 to %ptr
	%r242 = ptrtoint %ptr %r238 to %word
	%r241 = ptrtoint %ptr %r237 to %word
	%r240 = icmp eq %word %r242, %r241
	%r239 = inttoptr i1 %r240 to %ptr
	%r244 = ptrtoint %ptr %r239 to %word
	%r243 = icmp ne %word %r244, 0
	br i1 %r243, label %L700, label %L706
L706:
	br label %L700
L700:
	%r245 = load %ptr, %ptr* %t10
	%r246 = inttoptr %word 1 to %ptr
	%r247 = inttoptr %word 1 to %ptr
	%r248 = load %ptr, %ptr* %t4
	%r252 = bitcast %ptr %r248 to [0 x %ptr]*
	%r251 = ptrtoint %ptr %r247 to %word
	%r250 = getelementptr [0 x %ptr], [0 x %ptr]* %r252, %word 0, %word %r251
	%r249 = load %ptr, %ptr* %r250
	%r256 = bitcast %ptr %r249 to [0 x %ptr]*
	%r255 = ptrtoint %ptr %r246 to %word
	%r254 = getelementptr [0 x %ptr], [0 x %ptr]* %r256, %word 0, %word %r255
	%r253 = load %ptr, %ptr* %r254
	store %ptr %r253, %ptr* %t9
	%r257 = inttoptr %word 0 to %ptr
	store %ptr %r257, %ptr* %t8
	br label %L708
L707:
	%r258 = inttoptr %word 0 to %ptr
	%r259 = load %ptr, %ptr* %t9
	%r263 = bitcast %ptr %r259 to [0 x %ptr]*
	%r262 = ptrtoint %ptr %r258 to %word
	%r261 = getelementptr [0 x %ptr], [0 x %ptr]* %r263, %word 0, %word %r262
	%r260 = load %ptr, %ptr* %r261
	%r264 = load %ptr, %ptr* %t7
	%r265 = call %ptr @"k/eval"(%ptr %r260, %ptr %r264)
	store %ptr %r265, %ptr* %t8
	%r266 = inttoptr %word 1 to %ptr
	%r267 = load %ptr, %ptr* %t9
	%r271 = bitcast %ptr %r267 to [0 x %ptr]*
	%r270 = ptrtoint %ptr %r266 to %word
	%r269 = getelementptr [0 x %ptr], [0 x %ptr]* %r271, %word 0, %word %r270
	%r268 = load %ptr, %ptr* %r269
	store %ptr %r268, %ptr* %t9
	br label %L708
L708:
	%r272 = load %ptr, %ptr* %t9
	%r273 = call %ptr @"get/type"(%ptr %r272)
	%r274 = inttoptr %word 19 to %ptr
	%r278 = ptrtoint %ptr %r274 to %word
	%r277 = ptrtoint %ptr %r273 to %word
	%r276 = icmp eq %word %r278, %r277
	%r275 = inttoptr i1 %r276 to %ptr
	%r280 = ptrtoint %ptr %r275 to %word
	%r279 = icmp ne %word %r280, 0
	br i1 %r279, label %L707, label %L709
L709:
	%r281 = inttoptr %word 1 to %ptr
	store %ptr %r281, %ptr* %t10
	%r282 = load %ptr, %ptr* %t5
	store %ptr %r282, %ptr* %t11
	%r283 = inttoptr %word 0 to %ptr
	%r284 = inttoptr %word 4 to %ptr
	%r285 = load %ptr, %ptr* %t11
	%r289 = bitcast %ptr %r285 to [0 x %ptr]*
	%r288 = ptrtoint %ptr %r284 to %word
	%r287 = getelementptr [0 x %ptr], [0 x %ptr]* %r289, %word 0, %word %r288
	%r286 = load %ptr, %ptr* %r287
	store %ptr %r286, %ptr* %t10
	%r290 = inttoptr %word 0 to %ptr
	%r294 = ptrtoint %ptr %r290 to %word
	%r293 = ptrtoint %ptr %r286 to %word
	%r292 = icmp eq %word %r294, %r293
	%r291 = inttoptr i1 %r292 to %ptr
	%r296 = ptrtoint %ptr %r291 to %word
	%r295 = icmp ne %word %r296, 0
	br i1 %r295, label %L710, label %L711
L711:
	%r297 = load %ptr, %ptr* %t7
	store %ptr %r297, %ptr* %t11
	%r298 = inttoptr %word 0 to %ptr
	%r299 = inttoptr %word 0 to %ptr
	%r300 = inttoptr %word 3 to %ptr
	%r301 = load %ptr, %ptr* %t11
	%r305 = bitcast %ptr %r301 to [0 x %ptr]*
	%r304 = ptrtoint %ptr %r300 to %word
	%r303 = getelementptr [0 x %ptr], [0 x %ptr]* %r305, %word 0, %word %r304
	store %ptr %r299, %ptr* %r303
	%r302 = bitcast %ptr %r299 to %ptr
	store %ptr %r302, %ptr* %t10
	%r306 = inttoptr %word 0 to %ptr
	%r310 = ptrtoint %ptr %r306 to %word
	%r309 = ptrtoint %ptr %r302 to %word
	%r308 = icmp eq %word %r310, %r309
	%r307 = inttoptr i1 %r308 to %ptr
	%r312 = ptrtoint %ptr %r307 to %word
	%r311 = icmp ne %word %r312, 0
	br i1 %r311, label %L710, label %L712
L712:
	br label %L710
L710:
	%r313 = load %ptr, %ptr* %t10
	%r314 = load %ptr, %ptr* %t8
	store %ptr %r314, %ptr* %t8
	%r316 = getelementptr %ptr, %ptr* %t7, %word 0
	%r315 = bitcast %ptr* %r316 to %ptr
	%r317 = call %ptr @"gc/pop-root"(%ptr %r315)
	%r318 = load %ptr, %ptr* %t8
	ret %ptr %r318
}
@str715 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str716 = private unnamed_addr constant [20 x i8] c"k/apply: fun is nil\00"
@str717 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str731 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str732 = private unnamed_addr constant [15 x i8] c"cannot apply: \00"
@str733 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/apply"(%ptr %fun, %ptr %arguments, %ptr %ctx) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %fun, %ptr* %t1
	store %ptr %arguments, %ptr* %t2
	store %ptr %ctx, %ptr* %t3
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	store %ptr %r2, %ptr* %t4
	%r3 = load %ptr, %ptr* %t1
	store %ptr %r3, %ptr* %t4
	%r4 = inttoptr %word 0 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	%r10 = ptrtoint %ptr %r5 to %word
	%r9 = icmp ne %word %r10, 0
	br i1 %r9, label %L714, label %L713
L714:
	%r11 = getelementptr [9 x i8], [9 x i8]* @str715, %word 0, %word 0
	%r13 = call i32 (%ptr, ...) @printf(%ptr %r11)
	%r14 = inttoptr %word %r13 to %ptr
	%r15 = getelementptr [20 x i8], [20 x i8]* @str716, %word 0, %word 0
	%r17 = call i32 (%ptr, ...) @printf(%ptr %r15)
	%r18 = inttoptr %word %r17 to %ptr
	%r19 = getelementptr [2 x i8], [2 x i8]* @str717, %word 0, %word 0
	%r21 = call i32 (%ptr, ...) @printf(%ptr %r19)
	%r22 = inttoptr %word %r21 to %ptr
	%r23 = call %ptr @die()
	store %ptr %r23, %ptr* %t4
	%r24 = inttoptr %word 0 to %ptr
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = icmp eq %word %r28, %r27
	%r25 = inttoptr i1 %r26 to %ptr
	%r30 = ptrtoint %ptr %r25 to %word
	%r29 = icmp ne %word %r30, 0
	br i1 %r29, label %L718, label %L713
L718:
	br label %L713
L713:
	%r31 = load %ptr, %ptr* %t4
	%r32 = load %ptr, %ptr* %t1
	%r33 = call %ptr @"get/type"(%ptr %r32)
	store %ptr %r33, %ptr* %t4
	%r34 = inttoptr %word 8 to %ptr
	%r35 = load %ptr, %ptr* %t4
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = icmp eq %word %r39, %r38
	%r36 = inttoptr i1 %r37 to %ptr
	%r41 = ptrtoint %ptr %r36 to %word
	%r40 = icmp ne %word %r41, 0
	br i1 %r40, label %L719, label %L720
L719:
	%r42 = load %ptr, %ptr* %t1
	%r43 = load %ptr, %ptr* %t2
	%r44 = load %ptr, %ptr* %t3
	%r45 = call %ptr @"k/apply-expr"(%ptr %r42, %ptr %r43, %ptr %r44)
	store %ptr %r45, %ptr* %t5
	br label %L721
L720:
	%r46 = inttoptr %word 10 to %ptr
	%r47 = load %ptr, %ptr* %t4
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r46 to %word
	%r49 = icmp eq %word %r51, %r50
	%r48 = inttoptr i1 %r49 to %ptr
	%r53 = ptrtoint %ptr %r48 to %word
	%r52 = icmp ne %word %r53, 0
	br i1 %r52, label %L722, label %L723
L722:
	%r54 = load %ptr, %ptr* %t1
	store %ptr %r54, %ptr* %t7
	%r55 = inttoptr %word 0 to %ptr
	%r56 = inttoptr %word 0 to %ptr
	%r57 = load %ptr, %ptr* %t7
	%r61 = bitcast %ptr %r57 to [0 x %ptr]*
	%r60 = ptrtoint %ptr %r56 to %word
	%r59 = getelementptr [0 x %ptr], [0 x %ptr]* %r61, %word 0, %word %r60
	%r58 = load %ptr, %ptr* %r59
	%r62 = load %ptr, %ptr* %t2
	%r63 = load %ptr, %ptr* %t3
	%r64 = call %ptr @"k/apply"(%ptr %r58, %ptr %r62, %ptr %r63)
	store %ptr %r64, %ptr* %t6
	br label %L724
L723:
	%r65 = inttoptr %word 11 to %ptr
	%r66 = load %ptr, %ptr* %t4
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = icmp eq %word %r70, %r69
	%r67 = inttoptr i1 %r68 to %ptr
	%r72 = ptrtoint %ptr %r67 to %word
	%r71 = icmp ne %word %r72, 0
	br i1 %r71, label %L725, label %L726
L725:
	%r73 = load %ptr, %ptr* %t1
	store %ptr %r73, %ptr* %t8
	%r74 = inttoptr %word 0 to %ptr
	%r75 = inttoptr %word 1 to %ptr
	%r76 = load %ptr, %ptr* %t8
	%r80 = bitcast %ptr %r76 to [0 x %ptr]*
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = getelementptr [0 x %ptr], [0 x %ptr]* %r80, %word 0, %word %r79
	%r77 = load %ptr, %ptr* %r78
	store %ptr %r77, %ptr* %t8
	%r81 = load %ptr, %ptr* %t2
	%r82 = load %ptr, %ptr* %t3
	%r83 = load %ptr, %ptr* %t8
	%r85 = bitcast %ptr %r83 to %ptr (%ptr, %ptr)*
	%r84 = call %ptr %r85(%ptr %r81, %ptr %r82)
	store %ptr %r84, %ptr* %t7
	br label %L727
L726:
	%r86 = load %ptr, %ptr* @"var/*applicators*"
	store %ptr %r86, %ptr* %t8
	%r87 = inttoptr %word 0 to %ptr
	%r88 = inttoptr %word 1 to %ptr
	%r89 = load %ptr, %ptr* %t8
	%r93 = bitcast %ptr %r89 to [0 x %ptr]*
	%r92 = ptrtoint %ptr %r88 to %word
	%r91 = getelementptr [0 x %ptr], [0 x %ptr]* %r93, %word 0, %word %r92
	%r90 = load %ptr, %ptr* %r91
	%r94 = load %ptr, %ptr* %t1
	%r95 = call %ptr @"get/type"(%ptr %r94)
	%r96 = call %ptr @"k/array-at"(%ptr %r90, %ptr %r95)
	store %ptr %r96, %ptr* %t8
	%r97 = load %ptr, %ptr* %t8
	%r99 = ptrtoint %ptr %r97 to %word
	%r98 = icmp ne %word %r99, 0
	br i1 %r98, label %L728, label %L729
L728:
	%r100 = load %ptr, %ptr* %t2
	store %ptr %r100, %ptr* %t10
	%r102 = getelementptr %ptr, %ptr* %t10, %word 0
	%r101 = bitcast %ptr* %r102 to %ptr
	%r103 = call %ptr @"gc/push-root"(%ptr %r101)
	%r104 = load %ptr, %ptr* %t1
	%r105 = load %ptr, %ptr* %t10
	%r106 = call %ptr @"new-<pair>"(%ptr %r104, %ptr %r105)
	store %ptr %r106, %ptr* %t10
	%r107 = load %ptr, %ptr* %t8
	%r108 = load %ptr, %ptr* %t10
	%r109 = load %ptr, %ptr* %t3
	%r110 = call %ptr @"k/apply"(%ptr %r107, %ptr %r108, %ptr %r109)
	store %ptr %r110, %ptr* %t11
	%r112 = getelementptr %ptr, %ptr* %t10, %word 0
	%r111 = bitcast %ptr* %r112 to %ptr
	%r113 = call %ptr @"gc/pop-root"(%ptr %r111)
	%r114 = load %ptr, %ptr* %t11
	store %ptr %r114, %ptr* %t9
	br label %L730
L729:
	%r115 = getelementptr [9 x i8], [9 x i8]* @str731, %word 0, %word 0
	%r117 = call i32 (%ptr, ...) @printf(%ptr %r115)
	%r118 = inttoptr %word %r117 to %ptr
	%r119 = getelementptr [15 x i8], [15 x i8]* @str732, %word 0, %word 0
	%r121 = call i32 (%ptr, ...) @printf(%ptr %r119)
	%r122 = inttoptr %word %r121 to %ptr
	%r123 = load %ptr, %ptr* %t1
	%r124 = call %ptr @"k/print"(%ptr %r123)
	%r125 = getelementptr [2 x i8], [2 x i8]* @str733, %word 0, %word 0
	%r127 = call i32 (%ptr, ...) @printf(%ptr %r125)
	%r128 = inttoptr %word %r127 to %ptr
	%r129 = call %ptr @die()
	store %ptr %r129, %ptr* %t9
	br label %L730
L730:
	%r130 = load %ptr, %ptr* %t9
	store %ptr %r130, %ptr* %t7
	br label %L727
L727:
	%r131 = load %ptr, %ptr* %t7
	store %ptr %r131, %ptr* %t6
	br label %L724
L724:
	%r132 = load %ptr, %ptr* %t6
	store %ptr %r132, %ptr* %t5
	br label %L721
L721:
	%r133 = load %ptr, %ptr* %t5
	ret %ptr %r133
}
define %ptr @exlist(%ptr %list, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %list, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"get/type"(%ptr %r1)
	%r3 = inttoptr %word 19 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	%r9 = ptrtoint %ptr %r4 to %word
	%r8 = icmp ne %word %r9, 0
	br i1 %r8, label %L734, label %L735
L734:
	%r10 = inttoptr %word 0 to %ptr
	%r11 = load %ptr, %ptr* %t1
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	%r12 = load %ptr, %ptr* %r13
	%r16 = load %ptr, %ptr* %t2
	%r17 = call %ptr @"k/expand"(%ptr %r12, %ptr %r16)
	store %ptr %r17, %ptr* %t4
	%r19 = getelementptr %ptr, %ptr* %t4, %word 0
	%r18 = bitcast %ptr* %r19 to %ptr
	%r20 = call %ptr @"gc/push-root"(%ptr %r18)
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r27 = load %ptr, %ptr* %t2
	%r28 = call %ptr @exlist(%ptr %r23, %ptr %r27)
	store %ptr %r28, %ptr* %t5
	%r30 = getelementptr %ptr, %ptr* %t5, %word 0
	%r29 = bitcast %ptr* %r30 to %ptr
	%r31 = call %ptr @"gc/push-root"(%ptr %r29)
	%r32 = load %ptr, %ptr* %t4
	%r33 = load %ptr, %ptr* %t5
	%r34 = call %ptr @"new-<pair>"(%ptr %r32, %ptr %r33)
	store %ptr %r34, %ptr* %t6
	%r36 = getelementptr %ptr, %ptr* %t5, %word 0
	%r35 = bitcast %ptr* %r36 to %ptr
	%r37 = call %ptr @"gc/pop-root"(%ptr %r35)
	%r38 = load %ptr, %ptr* %t6
	store %ptr %r38, %ptr* %t5
	%r40 = getelementptr %ptr, %ptr* %t4, %word 0
	%r39 = bitcast %ptr* %r40 to %ptr
	%r41 = call %ptr @"gc/pop-root"(%ptr %r39)
	%r42 = load %ptr, %ptr* %t5
	store %ptr %r42, %ptr* %t3
	br label %L736
L735:
	%r43 = load %ptr, %ptr* %t1
	%r44 = load %ptr, %ptr* %t2
	%r45 = call %ptr @"k/expand"(%ptr %r43, %ptr %r44)
	store %ptr %r45, %ptr* %t3
	br label %L736
L736:
	%r46 = load %ptr, %ptr* %t3
	ret %ptr %r46
}
@str759 = private unnamed_addr constant [5 x i8] c"set-\00"
define %ptr @"k/expand"(%ptr %exp, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %exp, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"get/type"(%ptr %r2)
	%r4 = inttoptr %word 19 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	%r10 = ptrtoint %ptr %r5 to %word
	%r9 = icmp ne %word %r10, 0
	br i1 %r9, label %L737, label %L738
L737:
	%r11 = inttoptr %word 0 to %ptr
	%r12 = load %ptr, %ptr* %t1
	%r16 = bitcast %ptr %r12 to [0 x %ptr]*
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = getelementptr [0 x %ptr], [0 x %ptr]* %r16, %word 0, %word %r15
	%r13 = load %ptr, %ptr* %r14
	%r17 = load %ptr, %ptr* %t2
	%r18 = call %ptr @"k/expand"(%ptr %r13, %ptr %r17)
	store %ptr %r18, %ptr* %t4
	%r20 = getelementptr %ptr, %ptr* %t4, %word 0
	%r19 = bitcast %ptr* %r20 to %ptr
	%r21 = call %ptr @"gc/push-root"(%ptr %r19)
	%r22 = inttoptr %word 1 to %ptr
	store %ptr %r22, %ptr* %t5
	%r23 = load %ptr, %ptr* %t4
	%r24 = call %ptr @"get/type"(%ptr %r23)
	%r25 = inttoptr %word 18 to %ptr
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = icmp eq %word %r29, %r28
	%r26 = inttoptr i1 %r27 to %ptr
	store %ptr %r26, %ptr* %t5
	%r30 = inttoptr %word 0 to %ptr
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = ptrtoint %ptr %r26 to %word
	%r32 = icmp eq %word %r34, %r33
	%r31 = inttoptr i1 %r32 to %ptr
	%r36 = ptrtoint %ptr %r31 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L740, label %L741
L741:
	%r37 = load %ptr, %ptr* %t2
	%r38 = load %ptr, %ptr* %t4
	%r39 = call %ptr @"k/env/lookup-variable"(%ptr %r37, %ptr %r38)
	store %ptr %r39, %ptr* %t6
	%r40 = inttoptr %word 1 to %ptr
	store %ptr %r40, %ptr* %t7
	%r41 = load %ptr, %ptr* %t6
	%r42 = call %ptr @"get/type"(%ptr %r41)
	%r43 = inttoptr %word 12 to %ptr
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = icmp eq %word %r47, %r46
	%r44 = inttoptr i1 %r45 to %ptr
	store %ptr %r44, %ptr* %t7
	%r48 = inttoptr %word 0 to %ptr
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = ptrtoint %ptr %r44 to %word
	%r50 = icmp eq %word %r52, %r51
	%r49 = inttoptr i1 %r50 to %ptr
	%r54 = ptrtoint %ptr %r49 to %word
	%r53 = icmp ne %word %r54, 0
	br i1 %r53, label %L742, label %L743
L743:
	%r55 = load %ptr, %ptr* %t6
	store %ptr %r55, %ptr* %t8
	%r56 = inttoptr %word 0 to %ptr
	%r57 = inttoptr %word 1 to %ptr
	%r58 = load %ptr, %ptr* %t8
	%r62 = bitcast %ptr %r58 to [0 x %ptr]*
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = getelementptr [0 x %ptr], [0 x %ptr]* %r62, %word 0, %word %r61
	%r59 = load %ptr, %ptr* %r60
	store %ptr %r59, %ptr* %t6
	store %ptr %r59, %ptr* %t7
	%r63 = inttoptr %word 0 to %ptr
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r59 to %word
	%r65 = icmp eq %word %r67, %r66
	%r64 = inttoptr i1 %r65 to %ptr
	%r69 = ptrtoint %ptr %r64 to %word
	%r68 = icmp ne %word %r69, 0
	br i1 %r68, label %L742, label %L744
L744:
	br label %L742
L742:
	%r70 = load %ptr, %ptr* %t7
	%r71 = inttoptr %word 1 to %ptr
	store %ptr %r71, %ptr* %t7
	%r72 = load %ptr, %ptr* %t6
	%r73 = call %ptr @"get/type"(%ptr %r72)
	%r74 = inttoptr %word 9 to %ptr
	%r78 = ptrtoint %ptr %r74 to %word
	%r77 = ptrtoint %ptr %r73 to %word
	%r76 = icmp eq %word %r78, %r77
	%r75 = inttoptr i1 %r76 to %ptr
	store %ptr %r75, %ptr* %t7
	%r79 = inttoptr %word 0 to %ptr
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = ptrtoint %ptr %r75 to %word
	%r81 = icmp eq %word %r83, %r82
	%r80 = inttoptr i1 %r81 to %ptr
	%r85 = ptrtoint %ptr %r80 to %word
	%r84 = icmp ne %word %r85, 0
	br i1 %r84, label %L745, label %L746
L746:
	%r86 = load %ptr, %ptr* %t6
	store %ptr %r86, %ptr* %t8
	%r87 = inttoptr %word 0 to %ptr
	%r88 = inttoptr %word 0 to %ptr
	%r89 = load %ptr, %ptr* %t8
	%r93 = bitcast %ptr %r89 to [0 x %ptr]*
	%r92 = ptrtoint %ptr %r88 to %word
	%r91 = getelementptr [0 x %ptr], [0 x %ptr]* %r93, %word 0, %word %r92
	%r90 = load %ptr, %ptr* %r91
	store %ptr %r90, %ptr* %t8
	%r94 = inttoptr %word 1 to %ptr
	store %ptr %r94, %ptr* %t9
	%r95 = load %ptr, %ptr* %t8
	store %ptr %r95, %ptr* %t9
	%r96 = inttoptr %word 0 to %ptr
	%r100 = ptrtoint %ptr %r96 to %word
	%r99 = ptrtoint %ptr %r95 to %word
	%r98 = icmp eq %word %r100, %r99
	%r97 = inttoptr i1 %r98 to %ptr
	%r102 = ptrtoint %ptr %r97 to %word
	%r101 = icmp ne %word %r102, 0
	br i1 %r101, label %L747, label %L748
L748:
	%r103 = load %ptr, %ptr* %t2
	%r104 = inttoptr %word 1 to %ptr
	%r105 = load %ptr, %ptr* %t1
	%r109 = bitcast %ptr %r105 to [0 x %ptr]*
	%r108 = ptrtoint %ptr %r104 to %word
	%r107 = getelementptr [0 x %ptr], [0 x %ptr]* %r109, %word 0, %word %r108
	%r106 = load %ptr, %ptr* %r107
	%r110 = call %ptr @"new-<pair>"(%ptr %r103, %ptr %r106)
	store %ptr %r110, %ptr* %t10
	%r112 = getelementptr %ptr, %ptr* %t10, %word 0
	%r111 = bitcast %ptr* %r112 to %ptr
	%r113 = call %ptr @"gc/push-root"(%ptr %r111)
	%r114 = load %ptr, %ptr* %t8
	%r115 = load %ptr, %ptr* %t10
	%r116 = inttoptr %word 0 to %ptr
	%r117 = call %ptr @"k/apply"(%ptr %r114, %ptr %r115, %ptr %r116)
	store %ptr %r117, %ptr* %t4
	%r118 = load %ptr, %ptr* %t4
	%r119 = load %ptr, %ptr* %t2
	%r120 = call %ptr @"k/expand"(%ptr %r118, %ptr %r119)
	store %ptr %r120, %ptr* %t4
	store %ptr %r120, %ptr* %t11
	%r122 = getelementptr %ptr, %ptr* %t10, %word 0
	%r121 = bitcast %ptr* %r122 to %ptr
	%r123 = call %ptr @"gc/pop-root"(%ptr %r121)
	%r124 = load %ptr, %ptr* %t11
	%r126 = getelementptr %ptr, %ptr* %t4, %word 0
	%r125 = bitcast %ptr* %r126 to %ptr
	%r127 = call %ptr @"gc/pop-root"(%ptr %r125)
	%r128 = load %ptr, %ptr* %t4
	ret %ptr %r128
	store %ptr %r128, %ptr* %t9
	%r130 = inttoptr %word 0 to %ptr
	%r134 = ptrtoint %ptr %r130 to %word
	%r133 = ptrtoint %ptr %r128 to %word
	%r132 = icmp eq %word %r134, %r133
	%r131 = inttoptr i1 %r132 to %ptr
	%r136 = ptrtoint %ptr %r131 to %word
	%r135 = icmp ne %word %r136, 0
	br i1 %r135, label %L747, label %L749
L749:
	br label %L747
L747:
	%r137 = load %ptr, %ptr* %t9
	store %ptr %r137, %ptr* %t7
	%r138 = inttoptr %word 0 to %ptr
	%r142 = ptrtoint %ptr %r138 to %word
	%r141 = ptrtoint %ptr %r137 to %word
	%r140 = icmp eq %word %r142, %r141
	%r139 = inttoptr i1 %r140 to %ptr
	%r144 = ptrtoint %ptr %r139 to %word
	%r143 = icmp ne %word %r144, 0
	br i1 %r143, label %L745, label %L750
L750:
	br label %L745
L745:
	%r145 = load %ptr, %ptr* %t7
	store %ptr %r145, %ptr* %t5
	%r146 = inttoptr %word 0 to %ptr
	%r150 = ptrtoint %ptr %r146 to %word
	%r149 = ptrtoint %ptr %r145 to %word
	%r148 = icmp eq %word %r150, %r149
	%r147 = inttoptr i1 %r148 to %ptr
	%r152 = ptrtoint %ptr %r147 to %word
	%r151 = icmp ne %word %r152, 0
	br i1 %r151, label %L740, label %L751
L751:
	br label %L740
L740:
	%r153 = load %ptr, %ptr* %t5
	%r154 = inttoptr %word 1 to %ptr
	%r155 = load %ptr, %ptr* %t1
	%r159 = bitcast %ptr %r155 to [0 x %ptr]*
	%r158 = ptrtoint %ptr %r154 to %word
	%r157 = getelementptr [0 x %ptr], [0 x %ptr]* %r159, %word 0, %word %r158
	%r156 = load %ptr, %ptr* %r157
	store %ptr %r156, %ptr* %t5
	%r161 = getelementptr %ptr, %ptr* %t5, %word 0
	%r160 = bitcast %ptr* %r161 to %ptr
	%r162 = call %ptr @"gc/push-root"(%ptr %r160)
	%r163 = inttoptr %word 0 to %ptr
	store %ptr %r163, %ptr* %t6
	%r164 = load %ptr, %ptr* @"symbol/quote"
	%r165 = load %ptr, %ptr* %t4
	%r169 = ptrtoint %ptr %r165 to %word
	%r168 = ptrtoint %ptr %r164 to %word
	%r167 = icmp eq %word %r169, %r168
	%r166 = inttoptr i1 %r167 to %ptr
	store %ptr %r166, %ptr* %t6
	%r170 = inttoptr %word 0 to %ptr
	%r174 = ptrtoint %ptr %r170 to %word
	%r173 = ptrtoint %ptr %r166 to %word
	%r172 = icmp eq %word %r174, %r173
	%r171 = inttoptr i1 %r172 to %ptr
	%r176 = ptrtoint %ptr %r171 to %word
	%r175 = icmp ne %word %r176, 0
	br i1 %r175, label %L753, label %L752
L753:
	%r177 = load %ptr, %ptr* %t5
	%r178 = load %ptr, %ptr* %t2
	%r179 = call %ptr @exlist(%ptr %r177, %ptr %r178)
	store %ptr %r179, %ptr* %t5
	store %ptr %r179, %ptr* %t6
	%r180 = inttoptr %word 0 to %ptr
	%r184 = ptrtoint %ptr %r180 to %word
	%r183 = ptrtoint %ptr %r179 to %word
	%r182 = icmp eq %word %r184, %r183
	%r181 = inttoptr i1 %r182 to %ptr
	%r186 = ptrtoint %ptr %r181 to %word
	%r185 = icmp ne %word %r186, 0
	br i1 %r185, label %L754, label %L752
L754:
	br label %L752
L752:
	%r187 = load %ptr, %ptr* %t6
	%r188 = inttoptr %word 1 to %ptr
	store %ptr %r188, %ptr* %t6
	%r189 = load %ptr, %ptr* %t4
	%r190 = load %ptr, %ptr* @"symbol/set"
	%r194 = ptrtoint %ptr %r190 to %word
	%r193 = ptrtoint %ptr %r189 to %word
	%r192 = icmp eq %word %r194, %r193
	%r191 = inttoptr i1 %r192 to %ptr
	store %ptr %r191, %ptr* %t6
	%r195 = inttoptr %word 0 to %ptr
	%r199 = ptrtoint %ptr %r195 to %word
	%r198 = ptrtoint %ptr %r191 to %word
	%r197 = icmp eq %word %r199, %r198
	%r196 = inttoptr i1 %r197 to %ptr
	%r201 = ptrtoint %ptr %r196 to %word
	%r200 = icmp ne %word %r201, 0
	br i1 %r200, label %L755, label %L756
L756:
	%r202 = load %ptr, %ptr* %t5
	%r203 = call %ptr @"k/car"(%ptr %r202)
	%r204 = call %ptr @"get/type"(%ptr %r203)
	%r205 = inttoptr %word 19 to %ptr
	%r209 = ptrtoint %ptr %r205 to %word
	%r208 = ptrtoint %ptr %r204 to %word
	%r207 = icmp eq %word %r209, %r208
	%r206 = inttoptr i1 %r207 to %ptr
	store %ptr %r206, %ptr* %t6
	%r210 = inttoptr %word 0 to %ptr
	%r214 = ptrtoint %ptr %r210 to %word
	%r213 = ptrtoint %ptr %r206 to %word
	%r212 = icmp eq %word %r214, %r213
	%r211 = inttoptr i1 %r212 to %ptr
	%r216 = ptrtoint %ptr %r211 to %word
	%r215 = icmp ne %word %r216, 0
	br i1 %r215, label %L755, label %L757
L757:
	%r217 = load %ptr, %ptr* %t5
	%r218 = call %ptr @"k/caar"(%ptr %r217)
	%r219 = call %ptr @"get/type"(%ptr %r218)
	%r220 = inttoptr %word 18 to %ptr
	%r224 = ptrtoint %ptr %r220 to %word
	%r223 = ptrtoint %ptr %r219 to %word
	%r222 = icmp eq %word %r224, %r223
	%r221 = inttoptr i1 %r222 to %ptr
	store %ptr %r221, %ptr* %t6
	%r225 = inttoptr %word 0 to %ptr
	%r229 = ptrtoint %ptr %r225 to %word
	%r228 = ptrtoint %ptr %r221 to %word
	%r227 = icmp eq %word %r229, %r228
	%r226 = inttoptr i1 %r227 to %ptr
	%r231 = ptrtoint %ptr %r226 to %word
	%r230 = icmp ne %word %r231, 0
	br i1 %r230, label %L755, label %L758
L758:
	%r232 = call %ptr @new_buffer()
	store %ptr %r232, %ptr* %t7
	%r233 = load %ptr, %ptr* %t7
	%r234 = getelementptr [5 x i8], [5 x i8]* @str759, %word 0, %word 0
	%r236 = call %ptr @buffer_append_all(%ptr %r233, %ptr %r234)
	%r237 = load %ptr, %ptr* %t7
	%r238 = inttoptr %word 0 to %ptr
	%r239 = inttoptr %word 0 to %ptr
	%r240 = load %ptr, %ptr* %t5
	%r244 = bitcast %ptr %r240 to [0 x %ptr]*
	%r243 = ptrtoint %ptr %r239 to %word
	%r242 = getelementptr [0 x %ptr], [0 x %ptr]* %r244, %word 0, %word %r243
	%r241 = load %ptr, %ptr* %r242
	%r248 = bitcast %ptr %r241 to [0 x %ptr]*
	%r247 = ptrtoint %ptr %r238 to %word
	%r246 = getelementptr [0 x %ptr], [0 x %ptr]* %r248, %word 0, %word %r247
	%r245 = load %ptr, %ptr* %r246
	store %ptr %r245, %ptr* %t8
	%r249 = inttoptr %word 0 to %ptr
	%r250 = inttoptr %word 0 to %ptr
	%r251 = load %ptr, %ptr* %t8
	%r255 = bitcast %ptr %r251 to [0 x %ptr]*
	%r254 = ptrtoint %ptr %r250 to %word
	%r253 = getelementptr [0 x %ptr], [0 x %ptr]* %r255, %word 0, %word %r254
	%r252 = load %ptr, %ptr* %r253
	%r256 = call %ptr @buffer_append_all(%ptr %r237, %ptr %r252)
	%r257 = load %ptr, %ptr* %t7
	%r258 = call %ptr @buffer_contents(%ptr %r257)
	%r259 = call %ptr @intern(%ptr %r258)
	store %ptr %r259, %ptr* %t4
	%r260 = inttoptr %word 1 to %ptr
	%r261 = inttoptr %word 0 to %ptr
	%r262 = load %ptr, %ptr* %t5
	%r266 = bitcast %ptr %r262 to [0 x %ptr]*
	%r265 = ptrtoint %ptr %r261 to %word
	%r264 = getelementptr [0 x %ptr], [0 x %ptr]* %r266, %word 0, %word %r265
	%r263 = load %ptr, %ptr* %r264
	%r270 = bitcast %ptr %r263 to [0 x %ptr]*
	%r269 = ptrtoint %ptr %r260 to %word
	%r268 = getelementptr [0 x %ptr], [0 x %ptr]* %r270, %word 0, %word %r269
	%r267 = load %ptr, %ptr* %r268
	%r271 = inttoptr %word 1 to %ptr
	%r272 = load %ptr, %ptr* %t5
	%r276 = bitcast %ptr %r272 to [0 x %ptr]*
	%r275 = ptrtoint %ptr %r271 to %word
	%r274 = getelementptr [0 x %ptr], [0 x %ptr]* %r276, %word 0, %word %r275
	%r273 = load %ptr, %ptr* %r274
	%r277 = call %ptr @"k/concat-list"(%ptr %r267, %ptr %r273)
	store %ptr %r277, %ptr* %t5
	store %ptr %r277, %ptr* %t6
	%r278 = inttoptr %word 0 to %ptr
	%r282 = ptrtoint %ptr %r278 to %word
	%r281 = ptrtoint %ptr %r277 to %word
	%r280 = icmp eq %word %r282, %r281
	%r279 = inttoptr i1 %r280 to %ptr
	%r284 = ptrtoint %ptr %r279 to %word
	%r283 = icmp ne %word %r284, 0
	br i1 %r283, label %L755, label %L760
L760:
	br label %L755
L755:
	%r285 = load %ptr, %ptr* %t6
	%r286 = load %ptr, %ptr* %t4
	%r287 = load %ptr, %ptr* %t5
	%r288 = call %ptr @"new-<pair>"(%ptr %r286, %ptr %r287)
	store %ptr %r288, %ptr* %t1
	%r290 = getelementptr %ptr, %ptr* %t5, %word 0
	%r289 = bitcast %ptr* %r290 to %ptr
	%r291 = call %ptr @"gc/pop-root"(%ptr %r289)
	%r293 = getelementptr %ptr, %ptr* %t4, %word 0
	%r292 = bitcast %ptr* %r293 to %ptr
	%r294 = call %ptr @"gc/pop-root"(%ptr %r292)
	store %ptr %r294, %ptr* %t3
	br label %L739
L738:
	%r295 = load %ptr, %ptr* %t1
	%r296 = call %ptr @"get/type"(%ptr %r295)
	%r297 = inttoptr %word 18 to %ptr
	%r301 = ptrtoint %ptr %r297 to %word
	%r300 = ptrtoint %ptr %r296 to %word
	%r299 = icmp eq %word %r301, %r300
	%r298 = inttoptr i1 %r299 to %ptr
	%r303 = ptrtoint %ptr %r298 to %word
	%r302 = icmp ne %word %r303, 0
	br i1 %r302, label %L761, label %L762
L761:
	%r304 = load %ptr, %ptr* %t2
	%r305 = load %ptr, %ptr* %t1
	%r306 = call %ptr @"k/env/lookup-variable"(%ptr %r304, %ptr %r305)
	store %ptr %r306, %ptr* %t5
	%r307 = inttoptr %word 1 to %ptr
	store %ptr %r307, %ptr* %t6
	%r308 = load %ptr, %ptr* %t5
	%r309 = call %ptr @"get/type"(%ptr %r308)
	%r310 = inttoptr %word 12 to %ptr
	%r314 = ptrtoint %ptr %r310 to %word
	%r313 = ptrtoint %ptr %r309 to %word
	%r312 = icmp eq %word %r314, %r313
	%r311 = inttoptr i1 %r312 to %ptr
	store %ptr %r311, %ptr* %t6
	%r315 = inttoptr %word 0 to %ptr
	%r319 = ptrtoint %ptr %r315 to %word
	%r318 = ptrtoint %ptr %r311 to %word
	%r317 = icmp eq %word %r319, %r318
	%r316 = inttoptr i1 %r317 to %ptr
	%r321 = ptrtoint %ptr %r316 to %word
	%r320 = icmp ne %word %r321, 0
	br i1 %r320, label %L764, label %L765
L765:
	%r322 = load %ptr, %ptr* %t5
	store %ptr %r322, %ptr* %t7
	%r323 = inttoptr %word 0 to %ptr
	%r324 = inttoptr %word 1 to %ptr
	%r325 = load %ptr, %ptr* %t7
	%r329 = bitcast %ptr %r325 to [0 x %ptr]*
	%r328 = ptrtoint %ptr %r324 to %word
	%r327 = getelementptr [0 x %ptr], [0 x %ptr]* %r329, %word 0, %word %r328
	%r326 = load %ptr, %ptr* %r327
	store %ptr %r326, %ptr* %t5
	store %ptr %r326, %ptr* %t6
	%r330 = inttoptr %word 0 to %ptr
	%r334 = ptrtoint %ptr %r330 to %word
	%r333 = ptrtoint %ptr %r326 to %word
	%r332 = icmp eq %word %r334, %r333
	%r331 = inttoptr i1 %r332 to %ptr
	%r336 = ptrtoint %ptr %r331 to %word
	%r335 = icmp ne %word %r336, 0
	br i1 %r335, label %L764, label %L766
L766:
	br label %L764
L764:
	%r337 = load %ptr, %ptr* %t6
	%r338 = inttoptr %word 1 to %ptr
	store %ptr %r338, %ptr* %t6
	%r339 = load %ptr, %ptr* %t5
	%r340 = call %ptr @"get/type"(%ptr %r339)
	%r341 = inttoptr %word 9 to %ptr
	%r345 = ptrtoint %ptr %r341 to %word
	%r344 = ptrtoint %ptr %r340 to %word
	%r343 = icmp eq %word %r345, %r344
	%r342 = inttoptr i1 %r343 to %ptr
	store %ptr %r342, %ptr* %t6
	%r346 = inttoptr %word 0 to %ptr
	%r350 = ptrtoint %ptr %r346 to %word
	%r349 = ptrtoint %ptr %r342 to %word
	%r348 = icmp eq %word %r350, %r349
	%r347 = inttoptr i1 %r348 to %ptr
	%r352 = ptrtoint %ptr %r347 to %word
	%r351 = icmp ne %word %r352, 0
	br i1 %r351, label %L767, label %L768
L768:
	%r353 = load %ptr, %ptr* %t5
	store %ptr %r353, %ptr* %t7
	%r354 = inttoptr %word 0 to %ptr
	%r355 = inttoptr %word 1 to %ptr
	%r356 = load %ptr, %ptr* %t7
	%r360 = bitcast %ptr %r356 to [0 x %ptr]*
	%r359 = ptrtoint %ptr %r355 to %word
	%r358 = getelementptr [0 x %ptr], [0 x %ptr]* %r360, %word 0, %word %r359
	%r357 = load %ptr, %ptr* %r358
	store %ptr %r357, %ptr* %t7
	%r361 = inttoptr %word 1 to %ptr
	store %ptr %r361, %ptr* %t8
	%r362 = load %ptr, %ptr* %t7
	store %ptr %r362, %ptr* %t8
	%r363 = inttoptr %word 0 to %ptr
	%r367 = ptrtoint %ptr %r363 to %word
	%r366 = ptrtoint %ptr %r362 to %word
	%r365 = icmp eq %word %r367, %r366
	%r364 = inttoptr i1 %r365 to %ptr
	%r369 = ptrtoint %ptr %r364 to %word
	%r368 = icmp ne %word %r369, 0
	br i1 %r368, label %L769, label %L770
L770:
	%r370 = load %ptr, %ptr* %t1
	%r371 = inttoptr %word 0 to %ptr
	%r372 = call %ptr @"new-<pair>"(%ptr %r370, %ptr %r371)
	store %ptr %r372, %ptr* %t9
	%r374 = getelementptr %ptr, %ptr* %t9, %word 0
	%r373 = bitcast %ptr* %r374 to %ptr
	%r375 = call %ptr @"gc/push-root"(%ptr %r373)
	%r376 = load %ptr, %ptr* %t2
	%r377 = load %ptr, %ptr* %t9
	%r378 = call %ptr @"new-<pair>"(%ptr %r376, %ptr %r377)
	store %ptr %r378, %ptr* %t9
	%r379 = load %ptr, %ptr* %t7
	%r380 = load %ptr, %ptr* %t9
	%r381 = inttoptr %word 0 to %ptr
	%r382 = call %ptr @"k/apply"(%ptr %r379, %ptr %r380, %ptr %r381)
	store %ptr %r382, %ptr* %t9
	%r383 = load %ptr, %ptr* %t9
	%r384 = load %ptr, %ptr* %t2
	%r385 = call %ptr @"k/expand"(%ptr %r383, %ptr %r384)
	store %ptr %r385, %ptr* %t1
	store %ptr %r385, %ptr* %t10
	%r387 = getelementptr %ptr, %ptr* %t9, %word 0
	%r386 = bitcast %ptr* %r387 to %ptr
	%r388 = call %ptr @"gc/pop-root"(%ptr %r386)
	%r389 = load %ptr, %ptr* %t10
	store %ptr %r389, %ptr* %t8
	%r390 = inttoptr %word 0 to %ptr
	%r394 = ptrtoint %ptr %r390 to %word
	%r393 = ptrtoint %ptr %r389 to %word
	%r392 = icmp eq %word %r394, %r393
	%r391 = inttoptr i1 %r392 to %ptr
	%r396 = ptrtoint %ptr %r391 to %word
	%r395 = icmp ne %word %r396, 0
	br i1 %r395, label %L769, label %L771
L771:
	br label %L769
L769:
	%r397 = load %ptr, %ptr* %t8
	store %ptr %r397, %ptr* %t6
	%r398 = inttoptr %word 0 to %ptr
	%r402 = ptrtoint %ptr %r398 to %word
	%r401 = ptrtoint %ptr %r397 to %word
	%r400 = icmp eq %word %r402, %r401
	%r399 = inttoptr i1 %r400 to %ptr
	%r404 = ptrtoint %ptr %r399 to %word
	%r403 = icmp ne %word %r404, 0
	br i1 %r403, label %L767, label %L772
L772:
	br label %L767
L767:
	%r405 = load %ptr, %ptr* %t6
	store %ptr %r405, %ptr* %t4
	br label %L763
L762:
	%r406 = load %ptr, %ptr* @"var/*expanders*"
	store %ptr %r406, %ptr* %t5
	%r407 = inttoptr %word 0 to %ptr
	%r408 = inttoptr %word 1 to %ptr
	%r409 = load %ptr, %ptr* %t5
	%r413 = bitcast %ptr %r409 to [0 x %ptr]*
	%r412 = ptrtoint %ptr %r408 to %word
	%r411 = getelementptr [0 x %ptr], [0 x %ptr]* %r413, %word 0, %word %r412
	%r410 = load %ptr, %ptr* %r411
	%r414 = load %ptr, %ptr* %t1
	%r415 = call %ptr @"get/type"(%ptr %r414)
	%r416 = call %ptr @"k/array-at"(%ptr %r410, %ptr %r415)
	store %ptr %r416, %ptr* %t5
	%r417 = inttoptr %word 1 to %ptr
	store %ptr %r417, %ptr* %t6
	%r418 = load %ptr, %ptr* %t5
	store %ptr %r418, %ptr* %t6
	%r419 = inttoptr %word 0 to %ptr
	%r423 = ptrtoint %ptr %r419 to %word
	%r422 = ptrtoint %ptr %r418 to %word
	%r421 = icmp eq %word %r423, %r422
	%r420 = inttoptr i1 %r421 to %ptr
	%r425 = ptrtoint %ptr %r420 to %word
	%r424 = icmp ne %word %r425, 0
	br i1 %r424, label %L773, label %L774
L774:
	%r426 = load %ptr, %ptr* %t1
	%r427 = inttoptr %word 0 to %ptr
	%r428 = call %ptr @"new-<pair>"(%ptr %r426, %ptr %r427)
	store %ptr %r428, %ptr* %t7
	%r430 = getelementptr %ptr, %ptr* %t7, %word 0
	%r429 = bitcast %ptr* %r430 to %ptr
	%r431 = call %ptr @"gc/push-root"(%ptr %r429)
	%r432 = load %ptr, %ptr* %t5
	%r433 = load %ptr, %ptr* %t7
	%r434 = inttoptr %word 0 to %ptr
	%r435 = call %ptr @"k/apply"(%ptr %r432, %ptr %r433, %ptr %r434)
	store %ptr %r435, %ptr* %t1
	store %ptr %r435, %ptr* %t8
	%r437 = getelementptr %ptr, %ptr* %t7, %word 0
	%r436 = bitcast %ptr* %r437 to %ptr
	%r438 = call %ptr @"gc/pop-root"(%ptr %r436)
	%r439 = load %ptr, %ptr* %t8
	store %ptr %r439, %ptr* %t6
	%r440 = inttoptr %word 0 to %ptr
	%r444 = ptrtoint %ptr %r440 to %word
	%r443 = ptrtoint %ptr %r439 to %word
	%r442 = icmp eq %word %r444, %r443
	%r441 = inttoptr i1 %r442 to %ptr
	%r446 = ptrtoint %ptr %r441 to %word
	%r445 = icmp ne %word %r446, 0
	br i1 %r445, label %L773, label %L775
L775:
	br label %L773
L773:
	%r447 = load %ptr, %ptr* %t6
	store %ptr %r447, %ptr* %t4
	br label %L763
L763:
	%r448 = load %ptr, %ptr* %t4
	store %ptr %r448, %ptr* %t3
	br label %L739
L739:
	%r449 = load %ptr, %ptr* %t3
	%r450 = load %ptr, %ptr* %t1
	ret %ptr %r450
}
define %ptr @enlist(%ptr %list, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %list, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"get/type"(%ptr %r1)
	%r3 = inttoptr %word 19 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	%r9 = ptrtoint %ptr %r4 to %word
	%r8 = icmp ne %word %r9, 0
	br i1 %r8, label %L776, label %L777
L776:
	%r10 = inttoptr %word 0 to %ptr
	%r11 = load %ptr, %ptr* %t1
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	%r12 = load %ptr, %ptr* %r13
	%r16 = load %ptr, %ptr* %t2
	%r17 = call %ptr @"k/encode"(%ptr %r12, %ptr %r16)
	store %ptr %r17, %ptr* %t4
	%r19 = getelementptr %ptr, %ptr* %t4, %word 0
	%r18 = bitcast %ptr* %r19 to %ptr
	%r20 = call %ptr @"gc/push-root"(%ptr %r18)
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r27 = load %ptr, %ptr* %t2
	%r28 = call %ptr @enlist(%ptr %r23, %ptr %r27)
	store %ptr %r28, %ptr* %t5
	%r30 = getelementptr %ptr, %ptr* %t5, %word 0
	%r29 = bitcast %ptr* %r30 to %ptr
	%r31 = call %ptr @"gc/push-root"(%ptr %r29)
	%r32 = load %ptr, %ptr* %t4
	%r33 = load %ptr, %ptr* %t5
	%r34 = call %ptr @"new-<pair>"(%ptr %r32, %ptr %r33)
	store %ptr %r34, %ptr* %t6
	%r36 = getelementptr %ptr, %ptr* %t5, %word 0
	%r35 = bitcast %ptr* %r36 to %ptr
	%r37 = call %ptr @"gc/pop-root"(%ptr %r35)
	%r38 = load %ptr, %ptr* %t6
	store %ptr %r38, %ptr* %t5
	%r40 = getelementptr %ptr, %ptr* %t4, %word 0
	%r39 = bitcast %ptr* %r40 to %ptr
	%r41 = call %ptr @"gc/pop-root"(%ptr %r39)
	%r42 = load %ptr, %ptr* %t5
	store %ptr %r42, %ptr* %t3
	br label %L778
L777:
	%r43 = load %ptr, %ptr* %t1
	%r44 = load %ptr, %ptr* %t2
	%r45 = call %ptr @"k/encode"(%ptr %r43, %ptr %r44)
	store %ptr %r45, %ptr* %t3
	br label %L778
L778:
	%r46 = load %ptr, %ptr* %t3
	ret %ptr %r46
}
define %ptr @"k/encode"(%ptr %exp, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %exp, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"get/type"(%ptr %r2)
	%r4 = inttoptr %word 19 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	%r10 = ptrtoint %ptr %r5 to %word
	%r9 = icmp ne %word %r10, 0
	br i1 %r9, label %L779, label %L780
L779:
	%r11 = load %ptr, %ptr* %t1
	%r12 = load %ptr, %ptr* %t2
	%r13 = call %ptr @"k/encode/pair"(%ptr %r11, %ptr %r12)
	store %ptr %r13, %ptr* %t3
	br label %L781
L780:
	%r14 = load %ptr, %ptr* %t1
	%r15 = call %ptr @"get/type"(%ptr %r14)
	%r16 = inttoptr %word 18 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r22 = ptrtoint %ptr %r17 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L782, label %L783
L782:
	%r23 = load %ptr, %ptr* %t1
	%r24 = load %ptr, %ptr* %t2
	%r25 = call %ptr @"k/encode/symbol"(%ptr %r23, %ptr %r24)
	store %ptr %r25, %ptr* %t4
	br label %L784
L783:
	%r26 = load %ptr, %ptr* %t1
	%r27 = load %ptr, %ptr* %t2
	%r28 = call %ptr @"k/encode/other"(%ptr %r26, %ptr %r27)
	store %ptr %r28, %ptr* %t4
	br label %L784
L784:
	%r29 = load %ptr, %ptr* %t4
	store %ptr %r29, %ptr* %t3
	br label %L781
L781:
	%r30 = load %ptr, %ptr* %t3
	ret %ptr %r30
}
@str811 = private unnamed_addr constant [28 x i8] c"set: undefined variable: %s\00"
@str818 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str819 = private unnamed_addr constant [34 x i8] c"encode: malformed SET expression \00"
@str820 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"k/encode/pair"(%ptr %exp, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %exp, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r6 = bitcast %ptr %r2 to [0 x %ptr]*
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = getelementptr [0 x %ptr], [0 x %ptr]* %r6, %word 0, %word %r5
	%r3 = load %ptr, %ptr* %r4
	%r7 = load %ptr, %ptr* %t2
	%r8 = call %ptr @"k/encode"(%ptr %r3, %ptr %r7)
	store %ptr %r8, %ptr* %t3
	%r10 = getelementptr %ptr, %ptr* %t3, %word 0
	%r9 = bitcast %ptr* %r10 to %ptr
	%r11 = call %ptr @"gc/push-root"(%ptr %r9)
	%r12 = inttoptr %word 1 to %ptr
	%r13 = load %ptr, %ptr* %t1
	%r17 = bitcast %ptr %r13 to [0 x %ptr]*
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = getelementptr [0 x %ptr], [0 x %ptr]* %r17, %word 0, %word %r16
	%r14 = load %ptr, %ptr* %r15
	store %ptr %r14, %ptr* %t4
	%r19 = getelementptr %ptr, %ptr* %t4, %word 0
	%r18 = bitcast %ptr* %r19 to %ptr
	%r20 = call %ptr @"gc/push-root"(%ptr %r18)
	%r21 = load %ptr, %ptr* @"fixed-subr/let"
	%r22 = load %ptr, %ptr* %t3
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L785, label %L786
L785:
	%r29 = load %ptr, %ptr* %t1
	%r30 = call %ptr @"k/cadr"(%ptr %r29)
	store %ptr %r30, %ptr* %t6
	%r31 = load %ptr, %ptr* %t2
	%r32 = inttoptr %word 0 to %ptr
	%r33 = inttoptr %word 1 to %ptr
	%r34 = load %ptr, %ptr* %t2
	store %ptr %r34, %ptr* %t7
	%r35 = inttoptr %word 0 to %ptr
	%r36 = inttoptr %word 2 to %ptr
	%r37 = load %ptr, %ptr* %t7
	%r41 = bitcast %ptr %r37 to [0 x %ptr]*
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = getelementptr [0 x %ptr], [0 x %ptr]* %r41, %word 0, %word %r40
	%r38 = load %ptr, %ptr* %r39
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r33 to %word
	%r43 = ashr %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	%r46 = call %ptr @"new-<env>"(%ptr %r31, %ptr %r32, %ptr %r42)
	store %ptr %r46, %ptr* %t7
	%r48 = getelementptr %ptr, %ptr* %t7, %word 0
	%r47 = bitcast %ptr* %r48 to %ptr
	%r49 = call %ptr @"gc/push-root"(%ptr %r47)
	br label %L789
L788:
	%r50 = inttoptr %word 0 to %ptr
	%r51 = load %ptr, %ptr* %t6
	%r55 = bitcast %ptr %r51 to [0 x %ptr]*
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = getelementptr [0 x %ptr], [0 x %ptr]* %r55, %word 0, %word %r54
	%r52 = load %ptr, %ptr* %r53
	store %ptr %r52, %ptr* %t8
	%r56 = inttoptr %word 1 to %ptr
	store %ptr %r56, %ptr* %t9
	%r57 = load %ptr, %ptr* %t8
	%r58 = call %ptr @"get/type"(%ptr %r57)
	%r59 = inttoptr %word 19 to %ptr
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = ptrtoint %ptr %r58 to %word
	%r61 = icmp eq %word %r63, %r62
	%r60 = inttoptr i1 %r61 to %ptr
	store %ptr %r60, %ptr* %t9
	%r64 = inttoptr %word 0 to %ptr
	%r68 = ptrtoint %ptr %r64 to %word
	%r67 = ptrtoint %ptr %r60 to %word
	%r66 = icmp eq %word %r68, %r67
	%r65 = inttoptr i1 %r66 to %ptr
	%r70 = ptrtoint %ptr %r65 to %word
	%r69 = icmp ne %word %r70, 0
	br i1 %r69, label %L791, label %L792
L792:
	%r71 = inttoptr %word 0 to %ptr
	%r72 = load %ptr, %ptr* %t8
	%r76 = bitcast %ptr %r72 to [0 x %ptr]*
	%r75 = ptrtoint %ptr %r71 to %word
	%r74 = getelementptr [0 x %ptr], [0 x %ptr]* %r76, %word 0, %word %r75
	%r73 = load %ptr, %ptr* %r74
	store %ptr %r73, %ptr* %t8
	store %ptr %r73, %ptr* %t9
	%r77 = inttoptr %word 0 to %ptr
	%r81 = ptrtoint %ptr %r77 to %word
	%r80 = ptrtoint %ptr %r73 to %word
	%r79 = icmp eq %word %r81, %r80
	%r78 = inttoptr i1 %r79 to %ptr
	%r83 = ptrtoint %ptr %r78 to %word
	%r82 = icmp ne %word %r83, 0
	br i1 %r82, label %L791, label %L793
L793:
	br label %L791
L791:
	%r84 = load %ptr, %ptr* %t9
	%r85 = load %ptr, %ptr* %t7
	%r86 = load %ptr, %ptr* %t8
	%r87 = inttoptr %word 0 to %ptr
	%r88 = call %ptr @"k/env/define"(%ptr %r85, %ptr %r86, %ptr %r87)
	%r89 = inttoptr %word 1 to %ptr
	%r90 = load %ptr, %ptr* %t6
	%r94 = bitcast %ptr %r90 to [0 x %ptr]*
	%r93 = ptrtoint %ptr %r89 to %word
	%r92 = getelementptr [0 x %ptr], [0 x %ptr]* %r94, %word 0, %word %r93
	%r91 = load %ptr, %ptr* %r92
	store %ptr %r91, %ptr* %t6
	br label %L789
L789:
	%r95 = load %ptr, %ptr* %t6
	%r96 = call %ptr @"get/type"(%ptr %r95)
	%r97 = inttoptr %word 19 to %ptr
	%r101 = ptrtoint %ptr %r97 to %word
	%r100 = ptrtoint %ptr %r96 to %word
	%r99 = icmp eq %word %r101, %r100
	%r98 = inttoptr i1 %r99 to %ptr
	%r103 = ptrtoint %ptr %r98 to %word
	%r102 = icmp ne %word %r103, 0
	br i1 %r102, label %L788, label %L790
L790:
	%r104 = load %ptr, %ptr* %t4
	%r105 = load %ptr, %ptr* %t7
	%r106 = call %ptr @enlist(%ptr %r104, %ptr %r105)
	store %ptr %r106, %ptr* %t4
	%r107 = load %ptr, %ptr* %t7
	%r108 = load %ptr, %ptr* %t4
	%r109 = call %ptr @"new-<pair>"(%ptr %r107, %ptr %r108)
	store %ptr %r109, %ptr* %t4
	store %ptr %r109, %ptr* %t8
	%r111 = getelementptr %ptr, %ptr* %t7, %word 0
	%r110 = bitcast %ptr* %r111 to %ptr
	%r112 = call %ptr @"gc/pop-root"(%ptr %r110)
	%r113 = load %ptr, %ptr* %t8
	store %ptr %r113, %ptr* %t5
	br label %L787
L786:
	%r114 = load %ptr, %ptr* @"fixed-subr/lambda"
	%r115 = load %ptr, %ptr* %t3
	%r119 = ptrtoint %ptr %r115 to %word
	%r118 = ptrtoint %ptr %r114 to %word
	%r117 = icmp eq %word %r119, %r118
	%r116 = inttoptr i1 %r117 to %ptr
	%r121 = ptrtoint %ptr %r116 to %word
	%r120 = icmp ne %word %r121, 0
	br i1 %r120, label %L794, label %L795
L794:
	%r122 = load %ptr, %ptr* %t1
	%r123 = call %ptr @"k/cadr"(%ptr %r122)
	store %ptr %r123, %ptr* %t7
	%r124 = load %ptr, %ptr* %t2
	%r125 = inttoptr %word 1 to %ptr
	%r126 = inttoptr %word 0 to %ptr
	%r127 = call %ptr @"new-<env>"(%ptr %r124, %ptr %r125, %ptr %r126)
	store %ptr %r127, %ptr* %t8
	%r129 = getelementptr %ptr, %ptr* %t8, %word 0
	%r128 = bitcast %ptr* %r129 to %ptr
	%r130 = call %ptr @"gc/push-root"(%ptr %r128)
	br label %L798
L797:
	%r131 = load %ptr, %ptr* %t8
	%r132 = inttoptr %word 0 to %ptr
	%r133 = load %ptr, %ptr* %t7
	%r137 = bitcast %ptr %r133 to [0 x %ptr]*
	%r136 = ptrtoint %ptr %r132 to %word
	%r135 = getelementptr [0 x %ptr], [0 x %ptr]* %r137, %word 0, %word %r136
	%r134 = load %ptr, %ptr* %r135
	%r138 = inttoptr %word 0 to %ptr
	%r139 = call %ptr @"k/env/define"(%ptr %r131, %ptr %r134, %ptr %r138)
	%r140 = inttoptr %word 1 to %ptr
	%r141 = load %ptr, %ptr* %t7
	%r145 = bitcast %ptr %r141 to [0 x %ptr]*
	%r144 = ptrtoint %ptr %r140 to %word
	%r143 = getelementptr [0 x %ptr], [0 x %ptr]* %r145, %word 0, %word %r144
	%r142 = load %ptr, %ptr* %r143
	store %ptr %r142, %ptr* %t7
	br label %L798
L798:
	%r146 = load %ptr, %ptr* %t7
	%r147 = call %ptr @"get/type"(%ptr %r146)
	%r148 = inttoptr %word 19 to %ptr
	%r152 = ptrtoint %ptr %r148 to %word
	%r151 = ptrtoint %ptr %r147 to %word
	%r150 = icmp eq %word %r152, %r151
	%r149 = inttoptr i1 %r150 to %ptr
	%r154 = ptrtoint %ptr %r149 to %word
	%r153 = icmp ne %word %r154, 0
	br i1 %r153, label %L797, label %L799
L799:
	%r155 = inttoptr %word 1 to %ptr
	store %ptr %r155, %ptr* %t9
	%r156 = load %ptr, %ptr* %t7
	store %ptr %r156, %ptr* %t9
	%r157 = inttoptr %word 0 to %ptr
	%r161 = ptrtoint %ptr %r157 to %word
	%r160 = ptrtoint %ptr %r156 to %word
	%r159 = icmp eq %word %r161, %r160
	%r158 = inttoptr i1 %r159 to %ptr
	%r163 = ptrtoint %ptr %r158 to %word
	%r162 = icmp ne %word %r163, 0
	br i1 %r162, label %L800, label %L801
L801:
	%r164 = load %ptr, %ptr* %t8
	%r165 = load %ptr, %ptr* %t7
	%r166 = inttoptr %word 0 to %ptr
	%r167 = call %ptr @"k/env/define"(%ptr %r164, %ptr %r165, %ptr %r166)
	store %ptr %r167, %ptr* %t9
	%r168 = inttoptr %word 0 to %ptr
	%r172 = ptrtoint %ptr %r168 to %word
	%r171 = ptrtoint %ptr %r167 to %word
	%r170 = icmp eq %word %r172, %r171
	%r169 = inttoptr i1 %r170 to %ptr
	%r174 = ptrtoint %ptr %r169 to %word
	%r173 = icmp ne %word %r174, 0
	br i1 %r173, label %L800, label %L802
L802:
	br label %L800
L800:
	%r175 = load %ptr, %ptr* %t9
	%r176 = load %ptr, %ptr* %t4
	%r177 = load %ptr, %ptr* %t8
	%r178 = call %ptr @enlist(%ptr %r176, %ptr %r177)
	store %ptr %r178, %ptr* %t4
	%r179 = load %ptr, %ptr* %t8
	%r180 = load %ptr, %ptr* %t4
	%r181 = call %ptr @"new-<pair>"(%ptr %r179, %ptr %r180)
	store %ptr %r181, %ptr* %t4
	store %ptr %r181, %ptr* %t9
	%r183 = getelementptr %ptr, %ptr* %t8, %word 0
	%r182 = bitcast %ptr* %r183 to %ptr
	%r184 = call %ptr @"gc/pop-root"(%ptr %r182)
	%r185 = load %ptr, %ptr* %t9
	store %ptr %r185, %ptr* %t6
	br label %L796
L795:
	%r186 = load %ptr, %ptr* @"fixed-subr/define"
	%r187 = load %ptr, %ptr* %t3
	%r191 = ptrtoint %ptr %r187 to %word
	%r190 = ptrtoint %ptr %r186 to %word
	%r189 = icmp eq %word %r191, %r190
	%r188 = inttoptr i1 %r189 to %ptr
	%r193 = ptrtoint %ptr %r188 to %word
	%r192 = icmp ne %word %r193, 0
	br i1 %r192, label %L803, label %L804
L803:
	%r194 = load %ptr, %ptr* @"*module*"
	store %ptr %r194, %ptr* %t8
	%r195 = inttoptr %word 0 to %ptr
	%r196 = inttoptr %word 1 to %ptr
	%r197 = load %ptr, %ptr* %t8
	%r201 = bitcast %ptr %r197 to [0 x %ptr]*
	%r200 = ptrtoint %ptr %r196 to %word
	%r199 = getelementptr [0 x %ptr], [0 x %ptr]* %r201, %word 0, %word %r200
	%r198 = load %ptr, %ptr* %r199
	store %ptr %r198, %ptr* %t8
	%r202 = inttoptr %word 0 to %ptr
	%r203 = inttoptr %word 1 to %ptr
	%r204 = load %ptr, %ptr* %t8
	%r208 = bitcast %ptr %r204 to [0 x %ptr]*
	%r207 = ptrtoint %ptr %r203 to %word
	%r206 = getelementptr [0 x %ptr], [0 x %ptr]* %r208, %word 0, %word %r207
	%r205 = load %ptr, %ptr* %r206
	%r209 = load %ptr, %ptr* %t4
	%r210 = call %ptr @"k/car"(%ptr %r209)
	%r211 = call %ptr @"k/env/ensure-variable"(%ptr %r205, %ptr %r210)
	store %ptr %r211, %ptr* %t8
	%r212 = load %ptr, %ptr* %t4
	%r213 = call %ptr @"k/cdr"(%ptr %r212)
	%r214 = load %ptr, %ptr* %t2
	%r215 = call %ptr @enlist(%ptr %r213, %ptr %r214)
	store %ptr %r215, %ptr* %t4
	%r216 = load %ptr, %ptr* %t8
	%r217 = load %ptr, %ptr* %t4
	%r218 = call %ptr @"new-<pair>"(%ptr %r216, %ptr %r217)
	store %ptr %r218, %ptr* %t4
	store %ptr %r218, %ptr* %t7
	br label %L805
L804:
	%r219 = load %ptr, %ptr* @"fixed-subr/set"
	%r220 = load %ptr, %ptr* %t3
	%r224 = ptrtoint %ptr %r220 to %word
	%r223 = ptrtoint %ptr %r219 to %word
	%r222 = icmp eq %word %r224, %r223
	%r221 = inttoptr i1 %r222 to %ptr
	%r226 = ptrtoint %ptr %r221 to %word
	%r225 = icmp ne %word %r226, 0
	br i1 %r225, label %L806, label %L807
L806:
	%r227 = load %ptr, %ptr* %t2
	%r228 = load %ptr, %ptr* %t4
	%r229 = call %ptr @"k/car"(%ptr %r228)
	%r230 = call %ptr @"k/env/lookup-variable"(%ptr %r227, %ptr %r229)
	store %ptr %r230, %ptr* %t9
	%r231 = inttoptr %word 0 to %ptr
	store %ptr %r231, %ptr* %t10
	%r232 = load %ptr, %ptr* %t9
	store %ptr %r232, %ptr* %t10
	%r233 = inttoptr %word 0 to %ptr
	%r237 = ptrtoint %ptr %r233 to %word
	%r236 = ptrtoint %ptr %r232 to %word
	%r235 = icmp eq %word %r237, %r236
	%r234 = inttoptr i1 %r235 to %ptr
	%r239 = ptrtoint %ptr %r234 to %word
	%r238 = icmp ne %word %r239, 0
	br i1 %r238, label %L810, label %L809
L810:
	%r240 = getelementptr [28 x i8], [28 x i8]* @str811, %word 0, %word 0
	%r242 = load %ptr, %ptr* %t4
	%r243 = call %ptr @"k/car"(%ptr %r242)
	store %ptr %r243, %ptr* %t11
	%r244 = inttoptr %word 0 to %ptr
	%r245 = inttoptr %word 0 to %ptr
	%r246 = load %ptr, %ptr* %t11
	%r250 = bitcast %ptr %r246 to [0 x %ptr]*
	%r249 = ptrtoint %ptr %r245 to %word
	%r248 = getelementptr [0 x %ptr], [0 x %ptr]* %r250, %word 0, %word %r249
	%r247 = load %ptr, %ptr* %r248
	%r251 = call %ptr @fatal1(%ptr %r240, %ptr %r247)
	store %ptr %r251, %ptr* %t10
	%r252 = inttoptr %word 0 to %ptr
	%r256 = ptrtoint %ptr %r252 to %word
	%r255 = ptrtoint %ptr %r251 to %word
	%r254 = icmp eq %word %r256, %r255
	%r253 = inttoptr i1 %r254 to %ptr
	%r258 = ptrtoint %ptr %r253 to %word
	%r257 = icmp ne %word %r258, 0
	br i1 %r257, label %L812, label %L809
L812:
	br label %L809
L809:
	%r259 = load %ptr, %ptr* %t10
	%r260 = inttoptr %word 1 to %ptr
	store %ptr %r260, %ptr* %t10
	%r261 = inttoptr %word 0 to %ptr
	store %ptr %r261, %ptr* %t11
	%r262 = load %ptr, %ptr* %t4
	%r263 = call %ptr @"k/car"(%ptr %r262)
	%r267 = ptrtoint %ptr %r263 to %word
	%r266 = icmp eq %word %r267, 0
	%r265 = zext i1 %r266 to %word
	%r264 = inttoptr %word %r265 to %ptr
	store %ptr %r264, %ptr* %t11
	%r268 = inttoptr %word 0 to %ptr
	%r272 = ptrtoint %ptr %r268 to %word
	%r271 = ptrtoint %ptr %r264 to %word
	%r270 = icmp eq %word %r272, %r271
	%r269 = inttoptr i1 %r270 to %ptr
	%r274 = ptrtoint %ptr %r269 to %word
	%r273 = icmp ne %word %r274, 0
	br i1 %r273, label %L815, label %L814
L815:
	%r275 = load %ptr, %ptr* %t4
	%r276 = call %ptr @"k/cddr"(%ptr %r275)
	store %ptr %r276, %ptr* %t11
	%r277 = inttoptr %word 0 to %ptr
	%r281 = ptrtoint %ptr %r277 to %word
	%r280 = ptrtoint %ptr %r276 to %word
	%r279 = icmp eq %word %r281, %r280
	%r278 = inttoptr i1 %r279 to %ptr
	%r283 = ptrtoint %ptr %r278 to %word
	%r282 = icmp ne %word %r283, 0
	br i1 %r282, label %L816, label %L814
L816:
	br label %L814
L814:
	%r284 = load %ptr, %ptr* %t11
	store %ptr %r284, %ptr* %t10
	%r285 = inttoptr %word 0 to %ptr
	%r289 = ptrtoint %ptr %r285 to %word
	%r288 = ptrtoint %ptr %r284 to %word
	%r287 = icmp eq %word %r289, %r288
	%r286 = inttoptr i1 %r287 to %ptr
	%r291 = ptrtoint %ptr %r286 to %word
	%r290 = icmp ne %word %r291, 0
	br i1 %r290, label %L813, label %L817
L817:
	%r292 = getelementptr [9 x i8], [9 x i8]* @str818, %word 0, %word 0
	%r294 = call i32 (%ptr, ...) @printf(%ptr %r292)
	%r295 = inttoptr %word %r294 to %ptr
	%r296 = getelementptr [34 x i8], [34 x i8]* @str819, %word 0, %word 0
	%r298 = call i32 (%ptr, ...) @printf(%ptr %r296)
	%r299 = inttoptr %word %r298 to %ptr
	%r300 = load %ptr, %ptr* %t1
	%r301 = call %ptr @"k/print"(%ptr %r300)
	%r302 = getelementptr [2 x i8], [2 x i8]* @str820, %word 0, %word 0
	%r304 = call i32 (%ptr, ...) @printf(%ptr %r302)
	%r305 = inttoptr %word %r304 to %ptr
	%r306 = call %ptr @die()
	store %ptr %r306, %ptr* %t10
	%r307 = inttoptr %word 0 to %ptr
	%r311 = ptrtoint %ptr %r307 to %word
	%r310 = ptrtoint %ptr %r306 to %word
	%r309 = icmp eq %word %r311, %r310
	%r308 = inttoptr i1 %r309 to %ptr
	%r313 = ptrtoint %ptr %r308 to %word
	%r312 = icmp ne %word %r313, 0
	br i1 %r312, label %L813, label %L821
L821:
	br label %L813
L813:
	%r314 = load %ptr, %ptr* %t10
	%r315 = load %ptr, %ptr* %t4
	%r316 = call %ptr @"k/cdr"(%ptr %r315)
	%r317 = load %ptr, %ptr* %t2
	%r318 = call %ptr @enlist(%ptr %r316, %ptr %r317)
	store %ptr %r318, %ptr* %t4
	%r319 = load %ptr, %ptr* %t9
	%r320 = load %ptr, %ptr* %t4
	%r321 = call %ptr @"new-<pair>"(%ptr %r319, %ptr %r320)
	store %ptr %r321, %ptr* %t4
	store %ptr %r321, %ptr* %t8
	br label %L808
L807:
	%r322 = load %ptr, %ptr* @"fixed-subr/quote"
	%r323 = load %ptr, %ptr* %t3
	%r327 = ptrtoint %ptr %r323 to %word
	%r326 = ptrtoint %ptr %r322 to %word
	%r325 = icmp ne %word %r327, %r326
	%r324 = inttoptr i1 %r325 to %ptr
	%r329 = ptrtoint %ptr %r324 to %word
	%r328 = icmp ne %word %r329, 0
	br i1 %r328, label %L822, label %L823
L822:
	%r330 = load %ptr, %ptr* %t4
	%r331 = load %ptr, %ptr* %t2
	%r332 = call %ptr @enlist(%ptr %r330, %ptr %r331)
	store %ptr %r332, %ptr* %t4
	store %ptr %r332, %ptr* %t9
	br label %L824
L823:
	%r333 = inttoptr %word 0 to %ptr
	store %ptr %r333, %ptr* %t9
	br label %L824
L824:
	%r334 = load %ptr, %ptr* %t9
	store %ptr %r334, %ptr* %t8
	br label %L808
L808:
	%r335 = load %ptr, %ptr* %t8
	store %ptr %r335, %ptr* %t7
	br label %L805
L805:
	%r336 = load %ptr, %ptr* %t7
	store %ptr %r336, %ptr* %t6
	br label %L796
L796:
	%r337 = load %ptr, %ptr* %t6
	store %ptr %r337, %ptr* %t5
	br label %L787
L787:
	%r338 = load %ptr, %ptr* %t5
	%r339 = load %ptr, %ptr* %t3
	%r340 = load %ptr, %ptr* %t4
	%r341 = call %ptr @"new-<pair>"(%ptr %r339, %ptr %r340)
	store %ptr %r341, %ptr* %t5
	%r343 = getelementptr %ptr, %ptr* %t4, %word 0
	%r342 = bitcast %ptr* %r343 to %ptr
	%r344 = call %ptr @"gc/pop-root"(%ptr %r342)
	%r345 = load %ptr, %ptr* %t5
	store %ptr %r345, %ptr* %t4
	%r347 = getelementptr %ptr, %ptr* %t3, %word 0
	%r346 = bitcast %ptr* %r347 to %ptr
	%r348 = call %ptr @"gc/pop-root"(%ptr %r346)
	%r349 = load %ptr, %ptr* %t4
	ret %ptr %r349
}
@str827 = private unnamed_addr constant [33 x i8] c"undefined variable in encode: %s\00"
define %ptr @"k/encode/symbol"(%ptr %exp, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %exp, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = load %ptr, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/env/lookup-variable"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = load %ptr, %ptr* %t3
	store %ptr %r5, %ptr* %t4
	%r6 = inttoptr %word 0 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = icmp ne %word %r12, 0
	br i1 %r11, label %L826, label %L825
L826:
	%r13 = getelementptr [33 x i8], [33 x i8]* @str827, %word 0, %word 0
	%r15 = load %ptr, %ptr* %t1
	store %ptr %r15, %ptr* %t5
	%r16 = inttoptr %word 0 to %ptr
	%r17 = inttoptr %word 0 to %ptr
	%r18 = load %ptr, %ptr* %t5
	%r22 = bitcast %ptr %r18 to [0 x %ptr]*
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = getelementptr [0 x %ptr], [0 x %ptr]* %r22, %word 0, %word %r21
	%r19 = load %ptr, %ptr* %r20
	%r23 = call %ptr @fatal1(%ptr %r13, %ptr %r19)
	store %ptr %r23, %ptr* %t4
	%r24 = inttoptr %word 0 to %ptr
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = icmp eq %word %r28, %r27
	%r25 = inttoptr i1 %r26 to %ptr
	%r30 = ptrtoint %ptr %r25 to %word
	%r29 = icmp ne %word %r30, 0
	br i1 %r29, label %L828, label %L825
L828:
	br label %L825
L825:
	%r31 = load %ptr, %ptr* %t4
	%r32 = load %ptr, %ptr* %t3
	store %ptr %r32, %ptr* %t1
	%r33 = load %ptr, %ptr* %t1
	%r34 = call %ptr @"global-variable?"(%ptr %r33)
	%r36 = ptrtoint %ptr %r34 to %word
	%r35 = icmp ne %word %r36, 0
	br i1 %r35, label %L829, label %L830
L829:
	%r37 = load %ptr, %ptr* %t1
	store %ptr %r37, %ptr* %t5
	%r38 = inttoptr %word 0 to %ptr
	%r39 = inttoptr %word 1 to %ptr
	%r40 = load %ptr, %ptr* %t5
	%r44 = bitcast %ptr %r40 to [0 x %ptr]*
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = getelementptr [0 x %ptr], [0 x %ptr]* %r44, %word 0, %word %r43
	%r41 = load %ptr, %ptr* %r42
	store %ptr %r41, %ptr* %t5
	%r45 = inttoptr %word 1 to %ptr
	store %ptr %r45, %ptr* %t6
	%r46 = inttoptr %word 0 to %ptr
	store %ptr %r46, %ptr* %t7
	%r47 = load %ptr, %ptr* %t5
	%r48 = call %ptr @"get/type"(%ptr %r47)
	%r49 = inttoptr %word 9 to %ptr
	%r53 = ptrtoint %ptr %r49 to %word
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = icmp eq %word %r53, %r52
	%r50 = inttoptr i1 %r51 to %ptr
	store %ptr %r50, %ptr* %t7
	%r54 = inttoptr %word 0 to %ptr
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = ptrtoint %ptr %r50 to %word
	%r56 = icmp eq %word %r58, %r57
	%r55 = inttoptr i1 %r56 to %ptr
	%r60 = ptrtoint %ptr %r55 to %word
	%r59 = icmp ne %word %r60, 0
	br i1 %r59, label %L834, label %L833
L834:
	%r61 = load %ptr, %ptr* %t5
	%r62 = call %ptr @"get/type"(%ptr %r61)
	%r63 = inttoptr %word 10 to %ptr
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r62 to %word
	%r65 = icmp eq %word %r67, %r66
	%r64 = inttoptr i1 %r65 to %ptr
	store %ptr %r64, %ptr* %t7
	%r68 = inttoptr %word 0 to %ptr
	%r72 = ptrtoint %ptr %r68 to %word
	%r71 = ptrtoint %ptr %r64 to %word
	%r70 = icmp eq %word %r72, %r71
	%r69 = inttoptr i1 %r70 to %ptr
	%r74 = ptrtoint %ptr %r69 to %word
	%r73 = icmp ne %word %r74, 0
	br i1 %r73, label %L835, label %L833
L835:
	br label %L833
L833:
	%r75 = load %ptr, %ptr* %t7
	store %ptr %r75, %ptr* %t6
	%r76 = inttoptr %word 0 to %ptr
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = icmp eq %word %r80, %r79
	%r77 = inttoptr i1 %r78 to %ptr
	%r82 = ptrtoint %ptr %r77 to %word
	%r81 = icmp ne %word %r82, 0
	br i1 %r81, label %L832, label %L836
L836:
	%r83 = load %ptr, %ptr* %t5
	store %ptr %r83, %ptr* %t1
	store %ptr %r83, %ptr* %t6
	%r84 = inttoptr %word 0 to %ptr
	%r88 = ptrtoint %ptr %r84 to %word
	%r87 = ptrtoint %ptr %r83 to %word
	%r86 = icmp eq %word %r88, %r87
	%r85 = inttoptr i1 %r86 to %ptr
	%r90 = ptrtoint %ptr %r85 to %word
	%r89 = icmp ne %word %r90, 0
	br i1 %r89, label %L832, label %L837
L837:
	br label %L832
L832:
	%r91 = load %ptr, %ptr* %t6
	store %ptr %r91, %ptr* %t4
	br label %L831
L830:
	%r92 = load %ptr, %ptr* %t1
	store %ptr %r92, %ptr* %t5
	%r93 = inttoptr %word 0 to %ptr
	%r94 = inttoptr %word 2 to %ptr
	%r95 = load %ptr, %ptr* %t5
	%r99 = bitcast %ptr %r95 to [0 x %ptr]*
	%r98 = ptrtoint %ptr %r94 to %word
	%r97 = getelementptr [0 x %ptr], [0 x %ptr]* %r99, %word 0, %word %r98
	%r96 = load %ptr, %ptr* %r97
	store %ptr %r96, %ptr* %t5
	%r100 = inttoptr %word 0 to %ptr
	store %ptr %r100, %ptr* %t6
	%r101 = inttoptr %word 1 to %ptr
	%r102 = load %ptr, %ptr* %t2
	store %ptr %r102, %ptr* %t7
	%r103 = inttoptr %word 0 to %ptr
	%r104 = inttoptr %word 1 to %ptr
	%r105 = load %ptr, %ptr* %t7
	%r109 = bitcast %ptr %r105 to [0 x %ptr]*
	%r108 = ptrtoint %ptr %r104 to %word
	%r107 = getelementptr [0 x %ptr], [0 x %ptr]* %r109, %word 0, %word %r108
	%r106 = load %ptr, %ptr* %r107
	%r113 = ptrtoint %ptr %r106 to %word
	%r112 = ptrtoint %ptr %r101 to %word
	%r111 = ashr %word %r113, %r112
	%r110 = inttoptr %word %r111 to %ptr
	%r114 = inttoptr %word 1 to %ptr
	%r115 = load %ptr, %ptr* %t5
	store %ptr %r115, %ptr* %t7
	%r116 = inttoptr %word 0 to %ptr
	%r117 = inttoptr %word 1 to %ptr
	%r118 = load %ptr, %ptr* %t7
	%r122 = bitcast %ptr %r118 to [0 x %ptr]*
	%r121 = ptrtoint %ptr %r117 to %word
	%r120 = getelementptr [0 x %ptr], [0 x %ptr]* %r122, %word 0, %word %r121
	%r119 = load %ptr, %ptr* %r120
	%r126 = ptrtoint %ptr %r119 to %word
	%r125 = ptrtoint %ptr %r114 to %word
	%r124 = ashr %word %r126, %r125
	%r123 = inttoptr %word %r124 to %ptr
	%r130 = ptrtoint %ptr %r123 to %word
	%r129 = ptrtoint %ptr %r110 to %word
	%r128 = icmp eq %word %r130, %r129
	%r127 = inttoptr i1 %r128 to %ptr
	store %ptr %r127, %ptr* %t6
	%r131 = inttoptr %word 0 to %ptr
	%r135 = ptrtoint %ptr %r131 to %word
	%r134 = ptrtoint %ptr %r127 to %word
	%r133 = icmp eq %word %r135, %r134
	%r132 = inttoptr i1 %r133 to %ptr
	%r137 = ptrtoint %ptr %r132 to %word
	%r136 = icmp ne %word %r137, 0
	br i1 %r136, label %L839, label %L838
L839:
	%r138 = load %ptr, %ptr* %t5
	store %ptr %r138, %ptr* %t7
	%r139 = inttoptr %word 0 to %ptr
	%r140 = load %ptr, %ptr* @"symbol/t"
	%r141 = inttoptr %word 4 to %ptr
	%r142 = load %ptr, %ptr* %t7
	%r146 = bitcast %ptr %r142 to [0 x %ptr]*
	%r145 = ptrtoint %ptr %r141 to %word
	%r144 = getelementptr [0 x %ptr], [0 x %ptr]* %r146, %word 0, %word %r145
	store %ptr %r140, %ptr* %r144
	%r143 = bitcast %ptr %r140 to %ptr
	store %ptr %r143, %ptr* %t6
	%r147 = inttoptr %word 0 to %ptr
	%r151 = ptrtoint %ptr %r147 to %word
	%r150 = ptrtoint %ptr %r143 to %word
	%r149 = icmp eq %word %r151, %r150
	%r148 = inttoptr i1 %r149 to %ptr
	%r153 = ptrtoint %ptr %r148 to %word
	%r152 = icmp ne %word %r153, 0
	br i1 %r152, label %L840, label %L838
L840:
	br label %L838
L838:
	%r154 = load %ptr, %ptr* %t6
	store %ptr %r154, %ptr* %t4
	br label %L831
L831:
	%r155 = load %ptr, %ptr* %t4
	%r156 = load %ptr, %ptr* %t1
	ret %ptr %r156
}
define %ptr @"k/encode/other"(%ptr %exp, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %exp, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = load %ptr, %ptr* @"var/*encoders*"
	store %ptr %r1, %ptr* %t3
	%r2 = inttoptr %word 0 to %ptr
	%r3 = inttoptr %word 1 to %ptr
	%r4 = load %ptr, %ptr* %t3
	%r8 = bitcast %ptr %r4 to [0 x %ptr]*
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = getelementptr [0 x %ptr], [0 x %ptr]* %r8, %word 0, %word %r7
	%r5 = load %ptr, %ptr* %r6
	%r9 = load %ptr, %ptr* %t1
	%r10 = call %ptr @"get/type"(%ptr %r9)
	%r11 = call %ptr @"k/array-at"(%ptr %r5, %ptr %r10)
	store %ptr %r11, %ptr* %t3
	%r12 = inttoptr %word 1 to %ptr
	store %ptr %r12, %ptr* %t4
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t4
	%r14 = inttoptr %word 0 to %ptr
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = icmp eq %word %r18, %r17
	%r15 = inttoptr i1 %r16 to %ptr
	%r20 = ptrtoint %ptr %r15 to %word
	%r19 = icmp ne %word %r20, 0
	br i1 %r19, label %L841, label %L842
L842:
	%r21 = load %ptr, %ptr* %t2
	%r22 = inttoptr %word 0 to %ptr
	%r23 = call %ptr @"new-<pair>"(%ptr %r21, %ptr %r22)
	store %ptr %r23, %ptr* %t5
	%r25 = getelementptr %ptr, %ptr* %t5, %word 0
	%r24 = bitcast %ptr* %r25 to %ptr
	%r26 = call %ptr @"gc/push-root"(%ptr %r24)
	%r27 = load %ptr, %ptr* %t1
	%r28 = load %ptr, %ptr* %t5
	%r29 = call %ptr @"new-<pair>"(%ptr %r27, %ptr %r28)
	store %ptr %r29, %ptr* %t5
	%r30 = inttoptr %word 0 to %ptr
	%r31 = load %ptr, %ptr* %t3
	%r32 = load %ptr, %ptr* %t5
	%r33 = inttoptr %word 0 to %ptr
	%r34 = call %ptr @"k/apply"(%ptr %r31, %ptr %r32, %ptr %r33)
	store %ptr %r34, %ptr* %t1
	store %ptr %r34, %ptr* %t6
	%r36 = getelementptr %ptr, %ptr* %t5, %word 0
	%r35 = bitcast %ptr* %r36 to %ptr
	%r37 = call %ptr @"gc/pop-root"(%ptr %r35)
	%r38 = load %ptr, %ptr* %t6
	store %ptr %r38, %ptr* %t4
	%r39 = inttoptr %word 0 to %ptr
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = icmp eq %word %r43, %r42
	%r40 = inttoptr i1 %r41 to %ptr
	%r45 = ptrtoint %ptr %r40 to %word
	%r44 = icmp ne %word %r45, 0
	br i1 %r44, label %L841, label %L843
L843:
	br label %L841
L841:
	%r46 = load %ptr, %ptr* %t4
	%r47 = load %ptr, %ptr* %t1
	ret %ptr %r47
}
define %ptr @evlist(%ptr %obj, %ptr %ctx) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %obj, %ptr* %t1
	store %ptr %ctx, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"get/type"(%ptr %r1)
	%r3 = inttoptr %word 19 to %ptr
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = icmp eq %word %r7, %r6
	%r4 = inttoptr i1 %r5 to %ptr
	%r9 = ptrtoint %ptr %r4 to %word
	%r8 = icmp ne %word %r9, 0
	br i1 %r8, label %L844, label %L845
L844:
	%r10 = inttoptr %word 0 to %ptr
	%r11 = load %ptr, %ptr* %t1
	%r15 = bitcast %ptr %r11 to [0 x %ptr]*
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = getelementptr [0 x %ptr], [0 x %ptr]* %r15, %word 0, %word %r14
	%r12 = load %ptr, %ptr* %r13
	%r16 = load %ptr, %ptr* %t2
	%r17 = call %ptr @"k/eval"(%ptr %r12, %ptr %r16)
	store %ptr %r17, %ptr* %t4
	%r19 = getelementptr %ptr, %ptr* %t4, %word 0
	%r18 = bitcast %ptr* %r19 to %ptr
	%r20 = call %ptr @"gc/push-root"(%ptr %r18)
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r27 = load %ptr, %ptr* %t2
	%r28 = call %ptr @evlist(%ptr %r23, %ptr %r27)
	store %ptr %r28, %ptr* %t5
	%r30 = getelementptr %ptr, %ptr* %t5, %word 0
	%r29 = bitcast %ptr* %r30 to %ptr
	%r31 = call %ptr @"gc/push-root"(%ptr %r29)
	%r32 = load %ptr, %ptr* %t4
	%r33 = load %ptr, %ptr* %t5
	%r34 = call %ptr @"new-<pair>"(%ptr %r32, %ptr %r33)
	store %ptr %r34, %ptr* %t6
	%r36 = getelementptr %ptr, %ptr* %t5, %word 0
	%r35 = bitcast %ptr* %r36 to %ptr
	%r37 = call %ptr @"gc/pop-root"(%ptr %r35)
	%r38 = load %ptr, %ptr* %t6
	store %ptr %r38, %ptr* %t5
	%r40 = getelementptr %ptr, %ptr* %t4, %word 0
	%r39 = bitcast %ptr* %r40 to %ptr
	%r41 = call %ptr @"gc/pop-root"(%ptr %r39)
	%r42 = load %ptr, %ptr* %t5
	store %ptr %r42, %ptr* %t3
	br label %L846
L845:
	%r43 = load %ptr, %ptr* %t1
	store %ptr %r43, %ptr* %t3
	br label %L846
L846:
	%r44 = load %ptr, %ptr* %t3
	ret %ptr %r44
}
@str849 = private unnamed_addr constant [5 x i8] c";;; \00"
@str853 = private unnamed_addr constant [9 x i8] c"expd--> \00"
@str857 = private unnamed_addr constant [9 x i8] c"encd--> \00"
@str861 = private unnamed_addr constant [8 x i8] c";;; => \00"
define %ptr @"k/expand-encode-eval"(%ptr %form, %ptr %env) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %form, %ptr* %t1
	store %ptr %env, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	store %ptr %r1, %ptr* %t3
	%r3 = getelementptr %ptr, %ptr* %t3, %word 0
	%r2 = bitcast %ptr* %r3 to %ptr
	%r4 = call %ptr @"gc/push-root"(%ptr %r2)
	%r5 = inttoptr %word 0 to %ptr
	%r6 = inttoptr %word 0 to %ptr
	%r7 = load %ptr, %ptr* %t2
	%r8 = call %ptr @"new-base-<context>"(%ptr %r5, %ptr %r6, %ptr %r7)
	store %ptr %r8, %ptr* %t4
	%r10 = getelementptr %ptr, %ptr* %t4, %word 0
	%r9 = bitcast %ptr* %r10 to %ptr
	%r11 = call %ptr @"gc/push-root"(%ptr %r9)
	%r12 = inttoptr %word 1 to %ptr
	store %ptr %r12, %ptr* %t5
	%r13 = load %ptr, %ptr* @"*arg/verbose*"
	%r14 = inttoptr %word 0 to %ptr
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = icmp slt %word %r18, %r17
	%r15 = inttoptr i1 %r16 to %ptr
	store %ptr %r15, %ptr* %t5
	%r19 = inttoptr %word 0 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r15 to %word
	%r21 = icmp eq %word %r23, %r22
	%r20 = inttoptr i1 %r21 to %ptr
	%r25 = ptrtoint %ptr %r20 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L847, label %L848
L848:
	%r26 = getelementptr [5 x i8], [5 x i8]* @str849, %word 0, %word 0
	%r28 = call i32 (%ptr, ...) @printf(%ptr %r26)
	%r29 = inttoptr %word %r28 to %ptr
	%r30 = load %ptr, %ptr* %t3
	%r31 = call %ptr @"k/dumpln"(%ptr %r30)
	store %ptr %r31, %ptr* %t5
	%r32 = inttoptr %word 0 to %ptr
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = icmp eq %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	%r38 = ptrtoint %ptr %r33 to %word
	%r37 = icmp ne %word %r38, 0
	br i1 %r37, label %L847, label %L850
L850:
	br label %L847
L847:
	%r39 = load %ptr, %ptr* %t5
	%r40 = load %ptr, %ptr* %t3
	%r41 = load %ptr, %ptr* %t2
	%r42 = call %ptr @"k/expand"(%ptr %r40, %ptr %r41)
	store %ptr %r42, %ptr* %t3
	%r43 = inttoptr %word 1 to %ptr
	store %ptr %r43, %ptr* %t5
	%r44 = load %ptr, %ptr* @"*arg/verbose*"
	%r45 = inttoptr %word 2 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = icmp slt %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	store %ptr %r46, %ptr* %t5
	%r50 = inttoptr %word 0 to %ptr
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = ptrtoint %ptr %r46 to %word
	%r52 = icmp eq %word %r54, %r53
	%r51 = inttoptr i1 %r52 to %ptr
	%r56 = ptrtoint %ptr %r51 to %word
	%r55 = icmp ne %word %r56, 0
	br i1 %r55, label %L851, label %L852
L852:
	%r57 = getelementptr [9 x i8], [9 x i8]* @str853, %word 0, %word 0
	%r59 = call i32 (%ptr, ...) @printf(%ptr %r57)
	%r60 = inttoptr %word %r59 to %ptr
	%r61 = load %ptr, %ptr* %t3
	%r62 = call %ptr @"k/dumpln"(%ptr %r61)
	store %ptr %r62, %ptr* %t5
	%r63 = inttoptr %word 0 to %ptr
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r62 to %word
	%r65 = icmp eq %word %r67, %r66
	%r64 = inttoptr i1 %r65 to %ptr
	%r69 = ptrtoint %ptr %r64 to %word
	%r68 = icmp ne %word %r69, 0
	br i1 %r68, label %L851, label %L854
L854:
	br label %L851
L851:
	%r70 = load %ptr, %ptr* %t5
	%r71 = load %ptr, %ptr* %t3
	%r72 = load %ptr, %ptr* %t2
	%r73 = call %ptr @"k/encode"(%ptr %r71, %ptr %r72)
	store %ptr %r73, %ptr* %t3
	%r74 = inttoptr %word 1 to %ptr
	store %ptr %r74, %ptr* %t5
	%r75 = load %ptr, %ptr* @"*arg/verbose*"
	%r76 = inttoptr %word 2 to %ptr
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = ptrtoint %ptr %r75 to %word
	%r78 = icmp slt %word %r80, %r79
	%r77 = inttoptr i1 %r78 to %ptr
	store %ptr %r77, %ptr* %t5
	%r81 = inttoptr %word 0 to %ptr
	%r85 = ptrtoint %ptr %r81 to %word
	%r84 = ptrtoint %ptr %r77 to %word
	%r83 = icmp eq %word %r85, %r84
	%r82 = inttoptr i1 %r83 to %ptr
	%r87 = ptrtoint %ptr %r82 to %word
	%r86 = icmp ne %word %r87, 0
	br i1 %r86, label %L855, label %L856
L856:
	%r88 = getelementptr [9 x i8], [9 x i8]* @str857, %word 0, %word 0
	%r90 = call i32 (%ptr, ...) @printf(%ptr %r88)
	%r91 = inttoptr %word %r90 to %ptr
	%r92 = load %ptr, %ptr* %t3
	%r93 = call %ptr @"k/dumpln"(%ptr %r92)
	store %ptr %r93, %ptr* %t5
	%r94 = inttoptr %word 0 to %ptr
	%r98 = ptrtoint %ptr %r94 to %word
	%r97 = ptrtoint %ptr %r93 to %word
	%r96 = icmp eq %word %r98, %r97
	%r95 = inttoptr i1 %r96 to %ptr
	%r100 = ptrtoint %ptr %r95 to %word
	%r99 = icmp ne %word %r100, 0
	br i1 %r99, label %L855, label %L858
L858:
	br label %L855
L855:
	%r101 = load %ptr, %ptr* %t5
	%r102 = load %ptr, %ptr* %t3
	%r103 = load %ptr, %ptr* %t4
	%r104 = call %ptr @"k/eval"(%ptr %r102, %ptr %r103)
	store %ptr %r104, %ptr* %t3
	%r105 = inttoptr %word 1 to %ptr
	store %ptr %r105, %ptr* %t5
	%r106 = load %ptr, %ptr* @"*arg/verbose*"
	%r107 = inttoptr %word 0 to %ptr
	%r111 = ptrtoint %ptr %r107 to %word
	%r110 = ptrtoint %ptr %r106 to %word
	%r109 = icmp slt %word %r111, %r110
	%r108 = inttoptr i1 %r109 to %ptr
	store %ptr %r108, %ptr* %t5
	%r112 = inttoptr %word 0 to %ptr
	%r116 = ptrtoint %ptr %r112 to %word
	%r115 = ptrtoint %ptr %r108 to %word
	%r114 = icmp eq %word %r116, %r115
	%r113 = inttoptr i1 %r114 to %ptr
	%r118 = ptrtoint %ptr %r113 to %word
	%r117 = icmp ne %word %r118, 0
	br i1 %r117, label %L859, label %L860
L860:
	%r119 = getelementptr [8 x i8], [8 x i8]* @str861, %word 0, %word 0
	%r121 = call i32 (%ptr, ...) @printf(%ptr %r119)
	%r122 = inttoptr %word %r121 to %ptr
	%r123 = load %ptr, %ptr* %t3
	%r124 = call %ptr @"k/dumpln"(%ptr %r123)
	store %ptr %r124, %ptr* %t5
	%r125 = inttoptr %word 0 to %ptr
	%r129 = ptrtoint %ptr %r125 to %word
	%r128 = ptrtoint %ptr %r124 to %word
	%r127 = icmp eq %word %r129, %r128
	%r126 = inttoptr i1 %r127 to %ptr
	%r131 = ptrtoint %ptr %r126 to %word
	%r130 = icmp ne %word %r131, 0
	br i1 %r130, label %L859, label %L862
L862:
	br label %L859
L859:
	%r132 = load %ptr, %ptr* %t5
	%r133 = load %ptr, %ptr* %t3
	store %ptr %r133, %ptr* %t5
	%r135 = getelementptr %ptr, %ptr* %t4, %word 0
	%r134 = bitcast %ptr* %r135 to %ptr
	%r136 = call %ptr @"gc/pop-root"(%ptr %r134)
	%r137 = load %ptr, %ptr* %t5
	store %ptr %r137, %ptr* %t4
	%r139 = getelementptr %ptr, %ptr* %t3, %word 0
	%r138 = bitcast %ptr* %r139 to %ptr
	%r140 = call %ptr @"gc/pop-root"(%ptr %r138)
	%r141 = load %ptr, %ptr* %t4
	ret %ptr %r141
}
@str865 = private unnamed_addr constant [10 x i8] c"#!%*[^\0A\0D]\00"
@str875 = private unnamed_addr constant [2 x i8] c".\00"
@str879 = private unnamed_addr constant [23 x i8] c"\0Amorituri te salutant\0A\00"
define %ptr @"k/repl-stream"(%ptr %stream) {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %stream, %ptr* %t1
	%r1 = load %ptr, %ptr* @"var/*input*"
	store %ptr %r1, %ptr* %t2
	%r2 = inttoptr %word 0 to %ptr
	%r3 = inttoptr %word 1 to %ptr
	%r4 = inttoptr %word 1 to %ptr
	%r5 = load %ptr, %ptr* %t1
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = shl %word %r9, %r8
	%r6 = inttoptr %word %r7 to %ptr
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = ptrtoint %ptr %r3 to %word
	%r11 = add %word %r13, %r12
	%r10 = inttoptr %word %r11 to %ptr
	%r14 = inttoptr %word 1 to %ptr
	%r15 = load %ptr, %ptr* %t2
	%r19 = bitcast %ptr %r15 to [0 x %ptr]*
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = getelementptr [0 x %ptr], [0 x %ptr]* %r19, %word 0, %word %r18
	store %ptr %r10, %ptr* %r17
	%r16 = bitcast %ptr %r10 to %ptr
	%r20 = inttoptr %word 0 to %ptr
	store %ptr %r20, %ptr* %t2
	%r22 = getelementptr %ptr, %ptr* %t2, %word 0
	%r21 = bitcast %ptr* %r22 to %ptr
	%r23 = call %ptr @"gc/push-root"(%ptr %r21)
	%r24 = inttoptr %word 0 to %ptr
	store %ptr %r24, %ptr* %t3
	%r25 = load %ptr, %ptr* %t1
	%r26 = load %ptr, %ptr* @"libc/stdin"
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = icmp eq %word %r30, %r29
	%r27 = inttoptr i1 %r28 to %ptr
	store %ptr %r27, %ptr* %t3
	%r31 = inttoptr %word 0 to %ptr
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r27 to %word
	%r33 = icmp eq %word %r35, %r34
	%r32 = inttoptr i1 %r33 to %ptr
	%r37 = ptrtoint %ptr %r32 to %word
	%r36 = icmp ne %word %r37, 0
	br i1 %r36, label %L864, label %L863
L864:
	%r38 = load %ptr, %ptr* %t1
	%r39 = getelementptr [10 x i8], [10 x i8]* @str865, %word 0, %word 0
	%r41 = call i32 (%ptr, %ptr, ...) @fscanf(%ptr %r38, %ptr %r39)
	%r42 = inttoptr %word %r41 to %ptr
	store %ptr %r42, %ptr* %t3
	%r43 = inttoptr %word 0 to %ptr
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = icmp eq %word %r47, %r46
	%r44 = inttoptr i1 %r45 to %ptr
	%r49 = ptrtoint %ptr %r44 to %word
	%r48 = icmp ne %word %r49, 0
	br i1 %r48, label %L866, label %L863
L866:
	br label %L863
L863:
	%r50 = load %ptr, %ptr* %t3
	br label %L868
L867:
	%r51 = load %ptr, %ptr* @"*module*"
	store %ptr %r51, %ptr* %t3
	%r52 = inttoptr %word 0 to %ptr
	%r53 = inttoptr %word 1 to %ptr
	%r54 = load %ptr, %ptr* %t3
	%r58 = bitcast %ptr %r54 to [0 x %ptr]*
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = getelementptr [0 x %ptr], [0 x %ptr]* %r58, %word 0, %word %r57
	%r55 = load %ptr, %ptr* %r56
	store %ptr %r55, %ptr* %t3
	%r59 = inttoptr %word 0 to %ptr
	%r60 = inttoptr %word 1 to %ptr
	%r61 = load %ptr, %ptr* %t3
	%r65 = bitcast %ptr %r61 to [0 x %ptr]*
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = getelementptr [0 x %ptr], [0 x %ptr]* %r65, %word 0, %word %r64
	%r62 = load %ptr, %ptr* %r63
	%r66 = inttoptr %word 1 to %ptr
	%r67 = inttoptr %word 0 to %ptr
	%r68 = call %ptr @"new-<env>"(%ptr %r62, %ptr %r66, %ptr %r67)
	store %ptr %r68, %ptr* %t3
	%r70 = getelementptr %ptr, %ptr* %t3, %word 0
	%r69 = bitcast %ptr* %r70 to %ptr
	%r71 = call %ptr @"gc/push-root"(%ptr %r69)
	%r72 = load %ptr, %ptr* %t2
	%r73 = load %ptr, %ptr* %t3
	%r74 = call %ptr @"k/expand-encode-eval"(%ptr %r72, %ptr %r73)
	store %ptr %r74, %ptr* %t2
	%r75 = inttoptr %word 1 to %ptr
	store %ptr %r75, %ptr* %t4
	%r76 = load %ptr, %ptr* %t1
	%r77 = load %ptr, %ptr* @"libc/stdin"
	%r81 = ptrtoint %ptr %r77 to %word
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = icmp eq %word %r81, %r80
	%r78 = inttoptr i1 %r79 to %ptr
	store %ptr %r78, %ptr* %t4
	%r82 = inttoptr %word 0 to %ptr
	%r86 = ptrtoint %ptr %r82 to %word
	%r85 = ptrtoint %ptr %r78 to %word
	%r84 = icmp eq %word %r86, %r85
	%r83 = inttoptr i1 %r84 to %ptr
	%r88 = ptrtoint %ptr %r83 to %word
	%r87 = icmp ne %word %r88, 0
	br i1 %r87, label %L870, label %L871
L871:
	%r89 = load %ptr, %ptr* %t2
	%r90 = call %ptr @"k/dumpln"(%ptr %r89)
	store %ptr %r90, %ptr* %t4
	%r91 = inttoptr %word 0 to %ptr
	%r95 = ptrtoint %ptr %r91 to %word
	%r94 = ptrtoint %ptr %r90 to %word
	%r93 = icmp eq %word %r95, %r94
	%r92 = inttoptr i1 %r93 to %ptr
	%r97 = ptrtoint %ptr %r92 to %word
	%r96 = icmp ne %word %r97, 0
	br i1 %r96, label %L870, label %L872
L872:
	br label %L870
L870:
	%r98 = load %ptr, %ptr* %t4
	store %ptr %r98, %ptr* %t4
	%r100 = getelementptr %ptr, %ptr* %t3, %word 0
	%r99 = bitcast %ptr* %r100 to %ptr
	%r101 = call %ptr @"gc/pop-root"(%ptr %r99)
	%r102 = load %ptr, %ptr* %t4
	br label %L868
L868:
	%r103 = inttoptr %word 1 to %ptr
	store %ptr %r103, %ptr* %t3
	%r104 = load %ptr, %ptr* %t1
	%r105 = load %ptr, %ptr* @"libc/stdin"
	%r109 = ptrtoint %ptr %r105 to %word
	%r108 = ptrtoint %ptr %r104 to %word
	%r107 = icmp eq %word %r109, %r108
	%r106 = inttoptr i1 %r107 to %ptr
	store %ptr %r106, %ptr* %t3
	%r110 = inttoptr %word 0 to %ptr
	%r114 = ptrtoint %ptr %r110 to %word
	%r113 = ptrtoint %ptr %r106 to %word
	%r112 = icmp eq %word %r114, %r113
	%r111 = inttoptr i1 %r112 to %ptr
	%r116 = ptrtoint %ptr %r111 to %word
	%r115 = icmp ne %word %r116, 0
	br i1 %r115, label %L873, label %L874
L874:
	%r117 = load %ptr, %ptr* @"libc/stdout"
	%r118 = getelementptr [2 x i8], [2 x i8]* @str875, %word 0, %word 0
	%r120 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r117, %ptr %r118)
	%r121 = inttoptr %word %r120 to %ptr
	%r122 = call %ptr @"libc/flush-streams"()
	store %ptr %r122, %ptr* %t3
	%r123 = inttoptr %word 0 to %ptr
	%r127 = ptrtoint %ptr %r123 to %word
	%r126 = ptrtoint %ptr %r122 to %word
	%r125 = icmp eq %word %r127, %r126
	%r124 = inttoptr i1 %r125 to %ptr
	%r129 = ptrtoint %ptr %r124 to %word
	%r128 = icmp ne %word %r129, 0
	br i1 %r128, label %L873, label %L876
L876:
	br label %L873
L873:
	%r130 = load %ptr, %ptr* %t3
	%r131 = load %ptr, %ptr* %t1
	%r132 = call %ptr @"k/read"(%ptr %r131)
	store %ptr %r132, %ptr* %t2
	%r133 = load %ptr, %ptr* @"k/+done+"
	%r137 = ptrtoint %ptr %r133 to %word
	%r136 = ptrtoint %ptr %r132 to %word
	%r135 = icmp ne %word %r137, %r136
	%r134 = inttoptr i1 %r135 to %ptr
	%r139 = ptrtoint %ptr %r134 to %word
	%r138 = icmp ne %word %r139, 0
	br i1 %r138, label %L867, label %L869
L869:
	%r140 = inttoptr %word 1 to %ptr
	store %ptr %r140, %ptr* %t3
	%r141 = load %ptr, %ptr* %t1
	%r142 = load %ptr, %ptr* @"libc/stdin"
	%r146 = ptrtoint %ptr %r142 to %word
	%r145 = ptrtoint %ptr %r141 to %word
	%r144 = icmp eq %word %r146, %r145
	%r143 = inttoptr i1 %r144 to %ptr
	store %ptr %r143, %ptr* %t3
	%r147 = inttoptr %word 0 to %ptr
	%r151 = ptrtoint %ptr %r147 to %word
	%r150 = ptrtoint %ptr %r143 to %word
	%r149 = icmp eq %word %r151, %r150
	%r148 = inttoptr i1 %r149 to %ptr
	%r153 = ptrtoint %ptr %r148 to %word
	%r152 = icmp ne %word %r153, 0
	br i1 %r152, label %L877, label %L878
L878:
	%r154 = getelementptr [23 x i8], [23 x i8]* @str879, %word 0, %word 0
	%r156 = call i32 (%ptr, ...) @printf(%ptr %r154)
	%r157 = inttoptr %word %r156 to %ptr
	store %ptr %r157, %ptr* %t3
	%r158 = inttoptr %word 0 to %ptr
	%r162 = ptrtoint %ptr %r158 to %word
	%r161 = ptrtoint %ptr %r157 to %word
	%r160 = icmp eq %word %r162, %r161
	%r159 = inttoptr i1 %r160 to %ptr
	%r164 = ptrtoint %ptr %r159 to %word
	%r163 = icmp ne %word %r164, 0
	br i1 %r163, label %L877, label %L880
L880:
	br label %L877
L877:
	%r165 = load %ptr, %ptr* %t3
	%r166 = load %ptr, %ptr* %t2
	store %ptr %r166, %ptr* %t3
	%r168 = getelementptr %ptr, %ptr* %t2, %word 0
	%r167 = bitcast %ptr* %r168 to %ptr
	%r169 = call %ptr @"gc/pop-root"(%ptr %r167)
	%r170 = load %ptr, %ptr* %t3
	ret %ptr %r170
}
@str892 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str893 = private unnamed_addr constant [11 x i8] c"Operator '\00"
@str894 = private unnamed_addr constant [46 x i8] c"' called with the wrong number of arguments: \00"
@str895 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"%check-arity"(%ptr %op, %ptr %arity, %ptr %args) {
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %op, %ptr* %t1
	store %ptr %arity, %ptr* %t2
	store %ptr %args, %ptr* %t3
	%r1 = load %ptr, %ptr* %t2
	store %ptr %r1, %ptr* %t4
	%r2 = load %ptr, %ptr* %t3
	store %ptr %r2, %ptr* %t5
	br label %L882
L881:
	%r3 = inttoptr %word 1 to %ptr
	%r4 = load %ptr, %ptr* %t5
	%r8 = bitcast %ptr %r4 to [0 x %ptr]*
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = getelementptr [0 x %ptr], [0 x %ptr]* %r8, %word 0, %word %r7
	%r5 = load %ptr, %ptr* %r6
	store %ptr %r5, %ptr* %t5
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t4
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = sub %word %r14, %r13
	%r11 = inttoptr %word %r12 to %ptr
	store %ptr %r11, %ptr* %t4
	br label %L882
L882:
	%r15 = inttoptr %word 1 to %ptr
	store %ptr %r15, %ptr* %t6
	%r16 = load %ptr, %ptr* %t4
	%r17 = inttoptr %word 0 to %ptr
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp slt %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t6
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L884, label %L885
L885:
	%r29 = load %ptr, %ptr* %t5
	%r30 = call %ptr @"get/type"(%ptr %r29)
	%r31 = inttoptr %word 19 to %ptr
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = icmp eq %word %r35, %r34
	%r32 = inttoptr i1 %r33 to %ptr
	store %ptr %r32, %ptr* %t6
	%r36 = inttoptr %word 0 to %ptr
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r32 to %word
	%r38 = icmp eq %word %r40, %r39
	%r37 = inttoptr i1 %r38 to %ptr
	%r42 = ptrtoint %ptr %r37 to %word
	%r41 = icmp ne %word %r42, 0
	br i1 %r41, label %L884, label %L886
L886:
	br label %L884
L884:
	%r43 = load %ptr, %ptr* %t6
	%r45 = ptrtoint %ptr %r43 to %word
	%r44 = icmp ne %word %r45, 0
	br i1 %r44, label %L881, label %L883
L883:
	%r46 = inttoptr %word 0 to %ptr
	store %ptr %r46, %ptr* %t6
	%r47 = inttoptr %word 1 to %ptr
	store %ptr %r47, %ptr* %t7
	%r48 = load %ptr, %ptr* %t4
	%r49 = inttoptr %word 0 to %ptr
	%r53 = ptrtoint %ptr %r49 to %word
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = icmp eq %word %r53, %r52
	%r50 = inttoptr i1 %r51 to %ptr
	store %ptr %r50, %ptr* %t7
	%r54 = inttoptr %word 0 to %ptr
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = ptrtoint %ptr %r50 to %word
	%r56 = icmp eq %word %r58, %r57
	%r55 = inttoptr i1 %r56 to %ptr
	%r60 = ptrtoint %ptr %r55 to %word
	%r59 = icmp ne %word %r60, 0
	br i1 %r59, label %L888, label %L889
L889:
	%r61 = load %ptr, %ptr* %t5
	%r65 = ptrtoint %ptr %r61 to %word
	%r64 = icmp eq %word %r65, 0
	%r63 = zext i1 %r64 to %word
	%r62 = inttoptr %word %r63 to %ptr
	store %ptr %r62, %ptr* %t7
	%r66 = inttoptr %word 0 to %ptr
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = ptrtoint %ptr %r62 to %word
	%r68 = icmp eq %word %r70, %r69
	%r67 = inttoptr i1 %r68 to %ptr
	%r72 = ptrtoint %ptr %r67 to %word
	%r71 = icmp ne %word %r72, 0
	br i1 %r71, label %L888, label %L890
L890:
	br label %L888
L888:
	%r73 = load %ptr, %ptr* %t7
	store %ptr %r73, %ptr* %t6
	%r74 = inttoptr %word 0 to %ptr
	%r78 = ptrtoint %ptr %r74 to %word
	%r77 = ptrtoint %ptr %r73 to %word
	%r76 = icmp eq %word %r78, %r77
	%r75 = inttoptr i1 %r76 to %ptr
	%r80 = ptrtoint %ptr %r75 to %word
	%r79 = icmp ne %word %r80, 0
	br i1 %r79, label %L891, label %L887
L891:
	%r81 = getelementptr [9 x i8], [9 x i8]* @str892, %word 0, %word 0
	%r83 = call i32 (%ptr, ...) @printf(%ptr %r81)
	%r84 = inttoptr %word %r83 to %ptr
	%r85 = getelementptr [11 x i8], [11 x i8]* @str893, %word 0, %word 0
	%r87 = call i32 (%ptr, ...) @printf(%ptr %r85)
	%r88 = inttoptr %word %r87 to %ptr
	%r89 = load %ptr, %ptr* %t1
	%r90 = call %ptr @"k/print"(%ptr %r89)
	%r91 = getelementptr [46 x i8], [46 x i8]* @str894, %word 0, %word 0
	%r93 = call i32 (%ptr, ...) @printf(%ptr %r91)
	%r94 = inttoptr %word %r93 to %ptr
	%r95 = load %ptr, %ptr* %t3
	%r96 = call %ptr @"k/print"(%ptr %r95)
	%r97 = getelementptr [2 x i8], [2 x i8]* @str895, %word 0, %word 0
	%r99 = call i32 (%ptr, ...) @printf(%ptr %r97)
	%r100 = inttoptr %word %r99 to %ptr
	%r101 = call %ptr @die()
	store %ptr %r101, %ptr* %t6
	%r102 = inttoptr %word 0 to %ptr
	%r106 = ptrtoint %ptr %r102 to %word
	%r105 = ptrtoint %ptr %r101 to %word
	%r104 = icmp eq %word %r106, %r105
	%r103 = inttoptr i1 %r104 to %ptr
	%r108 = ptrtoint %ptr %r103 to %word
	%r107 = icmp ne %word %r108, 0
	br i1 %r107, label %L896, label %L887
L896:
	br label %L887
L887:
	%r109 = load %ptr, %ptr* %t6
	ret %ptr %r109
}
@str899 = private unnamed_addr constant [33 x i8] c"\0Aerror: non-variable in define: \00"
@str900 = private unnamed_addr constant [9 x i8] c"aborting\00"
define %ptr @"subr/define"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	store %ptr %r2, %ptr* %t3
	%r3 = inttoptr %word 0 to %ptr
	store %ptr %r3, %ptr* %t4
	%r4 = load %ptr, %ptr* %t3
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 12 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	store %ptr %r7, %ptr* %t4
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L898, label %L897
L898:
	%r18 = getelementptr [33 x i8], [33 x i8]* @str899, %word 0, %word 0
	%r20 = call i32 (%ptr, ...) @printf(%ptr %r18)
	%r21 = inttoptr %word %r20 to %ptr
	%r22 = load %ptr, %ptr* %t3
	%r23 = call %ptr @"k/dumpln"(%ptr %r22)
	%r24 = getelementptr [9 x i8], [9 x i8]* @str900, %word 0, %word 0
	%r26 = call %ptr @fatal(%ptr %r24)
	store %ptr %r26, %ptr* %t4
	%r27 = inttoptr %word 0 to %ptr
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = icmp eq %word %r31, %r30
	%r28 = inttoptr i1 %r29 to %ptr
	%r33 = ptrtoint %ptr %r28 to %word
	%r32 = icmp ne %word %r33, 0
	br i1 %r32, label %L901, label %L897
L901:
	br label %L897
L897:
	%r34 = load %ptr, %ptr* %t4
	%r35 = load %ptr, %ptr* %t1
	%r36 = call %ptr @"k/cadr"(%ptr %r35)
	%r37 = load %ptr, %ptr* %t2
	%r38 = call %ptr @"k/eval"(%ptr %r36, %ptr %r37)
	store %ptr %r38, %ptr* %t4
	%r39 = load %ptr, %ptr* %t3
	store %ptr %r39, %ptr* %t5
	%r40 = inttoptr %word 0 to %ptr
	%r41 = load %ptr, %ptr* %t4
	%r42 = inttoptr %word 1 to %ptr
	%r43 = load %ptr, %ptr* %t5
	%r47 = bitcast %ptr %r43 to [0 x %ptr]*
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = getelementptr [0 x %ptr], [0 x %ptr]* %r47, %word 0, %word %r46
	store %ptr %r41, %ptr* %r45
	%r44 = bitcast %ptr %r41 to %ptr
	ret %ptr %r44
}
define %ptr @"subr/defined?"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = load %ptr, %ptr* %t1
	%r6 = call %ptr @"k/cadr"(%ptr %r5)
	store %ptr %r6, %ptr* %t4
	%r7 = inttoptr %word 0 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	%r13 = ptrtoint %ptr %r8 to %word
	%r12 = icmp ne %word %r13, 0
	br i1 %r12, label %L903, label %L902
L903:
	%r14 = load %ptr, %ptr* @"*module*"
	store %ptr %r14, %ptr* %t5
	%r15 = inttoptr %word 0 to %ptr
	%r16 = inttoptr %word 1 to %ptr
	%r17 = load %ptr, %ptr* %t5
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	%r18 = load %ptr, %ptr* %r19
	store %ptr %r18, %ptr* %t5
	%r22 = inttoptr %word 0 to %ptr
	%r23 = inttoptr %word 1 to %ptr
	%r24 = load %ptr, %ptr* %t5
	%r28 = bitcast %ptr %r24 to [0 x %ptr]*
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = getelementptr [0 x %ptr], [0 x %ptr]* %r28, %word 0, %word %r27
	%r25 = load %ptr, %ptr* %r26
	store %ptr %r25, %ptr* %t4
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r25 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	%r35 = ptrtoint %ptr %r30 to %word
	%r34 = icmp ne %word %r35, 0
	br i1 %r34, label %L904, label %L902
L904:
	br label %L902
L902:
	%r36 = load %ptr, %ptr* %t4
	store %ptr %r36, %ptr* %t4
	%r37 = load %ptr, %ptr* %t4
	%r38 = load %ptr, %ptr* %t3
	%r39 = call %ptr @"k/env/lookup-variable"(%ptr %r37, %ptr %r38)
	ret %ptr %r39
}
define %ptr @"subr/lambda"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = load %ptr, %ptr* %t2
	%r3 = call %ptr @"new-<expr>"(%ptr %r1, %ptr %r2)
	ret %ptr %r3
}
define %ptr @"subr/let"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t10 = alloca %ptr
	%t9 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t3
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/cadr"(%ptr %r2)
	store %ptr %r3, %ptr* %t4
	%r4 = load %ptr, %ptr* %t2
	store %ptr %r4, %ptr* %t5
	%r5 = inttoptr %word 0 to %ptr
	%r6 = inttoptr %word 2 to %ptr
	%r7 = load %ptr, %ptr* %t5
	%r11 = bitcast %ptr %r7 to [0 x %ptr]*
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = getelementptr [0 x %ptr], [0 x %ptr]* %r11, %word 0, %word %r10
	%r8 = load %ptr, %ptr* %r9
	store %ptr %r8, %ptr* %t5
	%r12 = load %ptr, %ptr* %t1
	%r13 = call %ptr @"k/cddr"(%ptr %r12)
	store %ptr %r13, %ptr* %t6
	%r15 = getelementptr %ptr, %ptr* %t3, %word 0
	%r14 = bitcast %ptr* %r15 to %ptr
	%r16 = call %ptr @"gc/push-root"(%ptr %r14)
	br label %L906
L905:
	%r17 = inttoptr %word 0 to %ptr
	%r18 = load %ptr, %ptr* %t4
	%r22 = bitcast %ptr %r18 to [0 x %ptr]*
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = getelementptr [0 x %ptr], [0 x %ptr]* %r22, %word 0, %word %r21
	%r19 = load %ptr, %ptr* %r20
	store %ptr %r19, %ptr* %t7
	%r23 = inttoptr %word 1 to %ptr
	store %ptr %r23, %ptr* %t8
	%r24 = load %ptr, %ptr* %t7
	%r25 = call %ptr @"get/type"(%ptr %r24)
	%r26 = inttoptr %word 19 to %ptr
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = icmp eq %word %r30, %r29
	%r27 = inttoptr i1 %r28 to %ptr
	store %ptr %r27, %ptr* %t8
	%r31 = inttoptr %word 0 to %ptr
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r27 to %word
	%r33 = icmp eq %word %r35, %r34
	%r32 = inttoptr i1 %r33 to %ptr
	%r37 = ptrtoint %ptr %r32 to %word
	%r36 = icmp ne %word %r37, 0
	br i1 %r36, label %L908, label %L909
L909:
	%r38 = inttoptr %word 0 to %ptr
	%r39 = load %ptr, %ptr* %t7
	%r43 = bitcast %ptr %r39 to [0 x %ptr]*
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = getelementptr [0 x %ptr], [0 x %ptr]* %r43, %word 0, %word %r42
	%r40 = load %ptr, %ptr* %r41
	store %ptr %r40, %ptr* %t9
	%r44 = inttoptr %word 1 to %ptr
	%r45 = load %ptr, %ptr* %t7
	%r49 = bitcast %ptr %r45 to [0 x %ptr]*
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = getelementptr [0 x %ptr], [0 x %ptr]* %r49, %word 0, %word %r48
	%r46 = load %ptr, %ptr* %r47
	store %ptr %r46, %ptr* %t10
	%r50 = inttoptr %word 0 to %ptr
	store %ptr %r50, %ptr* %t3
	br label %L911
L910:
	%r51 = inttoptr %word 0 to %ptr
	%r52 = load %ptr, %ptr* %t10
	%r56 = bitcast %ptr %r52 to [0 x %ptr]*
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = getelementptr [0 x %ptr], [0 x %ptr]* %r56, %word 0, %word %r55
	%r53 = load %ptr, %ptr* %r54
	%r57 = load %ptr, %ptr* %t2
	%r58 = call %ptr @"k/eval"(%ptr %r53, %ptr %r57)
	store %ptr %r58, %ptr* %t3
	%r59 = inttoptr %word 1 to %ptr
	%r60 = load %ptr, %ptr* %t10
	%r64 = bitcast %ptr %r60 to [0 x %ptr]*
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = getelementptr [0 x %ptr], [0 x %ptr]* %r64, %word 0, %word %r63
	%r61 = load %ptr, %ptr* %r62
	store %ptr %r61, %ptr* %t10
	br label %L911
L911:
	%r65 = load %ptr, %ptr* %t10
	%r66 = call %ptr @"get/type"(%ptr %r65)
	%r67 = inttoptr %word 19 to %ptr
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = icmp eq %word %r71, %r70
	%r68 = inttoptr i1 %r69 to %ptr
	%r73 = ptrtoint %ptr %r68 to %word
	%r72 = icmp ne %word %r73, 0
	br i1 %r72, label %L910, label %L912
L912:
	%r74 = load %ptr, %ptr* %t5
	%r75 = inttoptr %word 1 to %ptr
	%r76 = load %ptr, %ptr* %t9
	store %ptr %r76, %ptr* %t11
	%r77 = inttoptr %word 0 to %ptr
	%r78 = inttoptr %word 3 to %ptr
	%r79 = load %ptr, %ptr* %t11
	%r83 = bitcast %ptr %r79 to [0 x %ptr]*
	%r82 = ptrtoint %ptr %r78 to %word
	%r81 = getelementptr [0 x %ptr], [0 x %ptr]* %r83, %word 0, %word %r82
	%r80 = load %ptr, %ptr* %r81
	%r87 = ptrtoint %ptr %r80 to %word
	%r86 = ptrtoint %ptr %r75 to %word
	%r85 = ashr %word %r87, %r86
	%r84 = inttoptr %word %r85 to %ptr
	%r88 = load %ptr, %ptr* %t3
	%r89 = call %ptr @"k/set-array-at"(%ptr %r74, %ptr %r84, %ptr %r88)
	store %ptr %r89, %ptr* %t8
	%r90 = inttoptr %word 0 to %ptr
	%r94 = ptrtoint %ptr %r90 to %word
	%r93 = ptrtoint %ptr %r89 to %word
	%r92 = icmp eq %word %r94, %r93
	%r91 = inttoptr i1 %r92 to %ptr
	%r96 = ptrtoint %ptr %r91 to %word
	%r95 = icmp ne %word %r96, 0
	br i1 %r95, label %L908, label %L913
L913:
	br label %L908
L908:
	%r97 = load %ptr, %ptr* %t8
	%r98 = inttoptr %word 1 to %ptr
	%r99 = load %ptr, %ptr* %t4
	%r103 = bitcast %ptr %r99 to [0 x %ptr]*
	%r102 = ptrtoint %ptr %r98 to %word
	%r101 = getelementptr [0 x %ptr], [0 x %ptr]* %r103, %word 0, %word %r102
	%r100 = load %ptr, %ptr* %r101
	store %ptr %r100, %ptr* %t4
	br label %L906
L906:
	%r104 = load %ptr, %ptr* %t4
	%r105 = call %ptr @"get/type"(%ptr %r104)
	%r106 = inttoptr %word 19 to %ptr
	%r110 = ptrtoint %ptr %r106 to %word
	%r109 = ptrtoint %ptr %r105 to %word
	%r108 = icmp eq %word %r110, %r109
	%r107 = inttoptr i1 %r108 to %ptr
	%r112 = ptrtoint %ptr %r107 to %word
	%r111 = icmp ne %word %r112, 0
	br i1 %r111, label %L905, label %L907
L907:
	%r113 = inttoptr %word 0 to %ptr
	store %ptr %r113, %ptr* %t3
	br label %L915
L914:
	%r114 = inttoptr %word 0 to %ptr
	%r115 = load %ptr, %ptr* %t6
	%r119 = bitcast %ptr %r115 to [0 x %ptr]*
	%r118 = ptrtoint %ptr %r114 to %word
	%r117 = getelementptr [0 x %ptr], [0 x %ptr]* %r119, %word 0, %word %r118
	%r116 = load %ptr, %ptr* %r117
	%r120 = load %ptr, %ptr* %t2
	%r121 = call %ptr @"k/eval"(%ptr %r116, %ptr %r120)
	store %ptr %r121, %ptr* %t3
	%r122 = inttoptr %word 1 to %ptr
	%r123 = load %ptr, %ptr* %t6
	%r127 = bitcast %ptr %r123 to [0 x %ptr]*
	%r126 = ptrtoint %ptr %r122 to %word
	%r125 = getelementptr [0 x %ptr], [0 x %ptr]* %r127, %word 0, %word %r126
	%r124 = load %ptr, %ptr* %r125
	store %ptr %r124, %ptr* %t6
	br label %L915
L915:
	%r128 = load %ptr, %ptr* %t6
	%r129 = call %ptr @"get/type"(%ptr %r128)
	%r130 = inttoptr %word 19 to %ptr
	%r134 = ptrtoint %ptr %r130 to %word
	%r133 = ptrtoint %ptr %r129 to %word
	%r132 = icmp eq %word %r134, %r133
	%r131 = inttoptr i1 %r132 to %ptr
	%r136 = ptrtoint %ptr %r131 to %word
	%r135 = icmp ne %word %r136, 0
	br i1 %r135, label %L914, label %L916
L916:
	store %ptr %r131, %ptr* %t7
	%r138 = getelementptr %ptr, %ptr* %t3, %word 0
	%r137 = bitcast %ptr* %r138 to %ptr
	%r139 = call %ptr @"gc/pop-root"(%ptr %r137)
	%r140 = load %ptr, %ptr* %t7
	%r141 = load %ptr, %ptr* %t3
	ret %ptr %r141
}
@str919 = private unnamed_addr constant [33 x i8] c"\0Acannot set undefined variable: \00"
@str920 = private unnamed_addr constant [9 x i8] c"aborting\00"
define %ptr @"subr/set"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = load %ptr, %ptr* %t3
	%r6 = call %ptr @"get/type"(%ptr %r5)
	%r7 = inttoptr %word 12 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	store %ptr %r8, %ptr* %t4
	%r12 = inttoptr %word 0 to %ptr
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = ptrtoint %ptr %r8 to %word
	%r14 = icmp eq %word %r16, %r15
	%r13 = inttoptr i1 %r14 to %ptr
	%r18 = ptrtoint %ptr %r13 to %word
	%r17 = icmp ne %word %r18, 0
	br i1 %r17, label %L918, label %L917
L918:
	%r19 = getelementptr [33 x i8], [33 x i8]* @str919, %word 0, %word 0
	%r21 = call i32 (%ptr, ...) @printf(%ptr %r19)
	%r22 = inttoptr %word %r21 to %ptr
	%r23 = load %ptr, %ptr* %t3
	%r24 = call %ptr @"k/dumpln"(%ptr %r23)
	%r25 = getelementptr [9 x i8], [9 x i8]* @str920, %word 0, %word 0
	%r27 = call %ptr @fatal(%ptr %r25)
	store %ptr %r27, %ptr* %t4
	%r28 = inttoptr %word 0 to %ptr
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = icmp eq %word %r32, %r31
	%r29 = inttoptr i1 %r30 to %ptr
	%r34 = ptrtoint %ptr %r29 to %word
	%r33 = icmp ne %word %r34, 0
	br i1 %r33, label %L921, label %L917
L921:
	br label %L917
L917:
	%r35 = load %ptr, %ptr* %t4
	%r36 = load %ptr, %ptr* %t1
	%r37 = call %ptr @"k/cadr"(%ptr %r36)
	%r38 = load %ptr, %ptr* %t2
	%r39 = call %ptr @"k/eval"(%ptr %r37, %ptr %r38)
	store %ptr %r39, %ptr* %t4
	%r40 = load %ptr, %ptr* %t3
	%r41 = call %ptr @"global-variable?"(%ptr %r40)
	%r43 = ptrtoint %ptr %r41 to %word
	%r42 = icmp ne %word %r43, 0
	br i1 %r42, label %L922, label %L923
L922:
	%r44 = load %ptr, %ptr* %t3
	store %ptr %r44, %ptr* %t6
	%r45 = inttoptr %word 0 to %ptr
	%r46 = load %ptr, %ptr* %t4
	%r47 = inttoptr %word 1 to %ptr
	%r48 = load %ptr, %ptr* %t6
	%r52 = bitcast %ptr %r48 to [0 x %ptr]*
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = getelementptr [0 x %ptr], [0 x %ptr]* %r52, %word 0, %word %r51
	store %ptr %r46, %ptr* %r50
	%r49 = bitcast %ptr %r46 to %ptr
	store %ptr %r49, %ptr* %t5
	br label %L924
L923:
	%r53 = inttoptr %word 1 to %ptr
	%r54 = load %ptr, %ptr* %t3
	store %ptr %r54, %ptr* %t6
	%r55 = inttoptr %word 0 to %ptr
	%r56 = inttoptr %word 2 to %ptr
	%r57 = load %ptr, %ptr* %t6
	%r61 = bitcast %ptr %r57 to [0 x %ptr]*
	%r60 = ptrtoint %ptr %r56 to %word
	%r59 = getelementptr [0 x %ptr], [0 x %ptr]* %r61, %word 0, %word %r60
	%r58 = load %ptr, %ptr* %r59
	store %ptr %r58, %ptr* %t6
	%r62 = inttoptr %word 0 to %ptr
	%r63 = inttoptr %word 1 to %ptr
	%r64 = load %ptr, %ptr* %t6
	%r68 = bitcast %ptr %r64 to [0 x %ptr]*
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = getelementptr [0 x %ptr], [0 x %ptr]* %r68, %word 0, %word %r67
	%r65 = load %ptr, %ptr* %r66
	%r72 = ptrtoint %ptr %r65 to %word
	%r71 = ptrtoint %ptr %r53 to %word
	%r70 = ashr %word %r72, %r71
	%r69 = inttoptr %word %r70 to %ptr
	%r73 = inttoptr %word 1 to %ptr
	%r74 = load %ptr, %ptr* %t2
	store %ptr %r74, %ptr* %t6
	%r75 = inttoptr %word 0 to %ptr
	%r76 = inttoptr %word 1 to %ptr
	%r77 = load %ptr, %ptr* %t6
	%r81 = bitcast %ptr %r77 to [0 x %ptr]*
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = getelementptr [0 x %ptr], [0 x %ptr]* %r81, %word 0, %word %r80
	%r78 = load %ptr, %ptr* %r79
	store %ptr %r78, %ptr* %t6
	%r82 = inttoptr %word 0 to %ptr
	%r83 = inttoptr %word 1 to %ptr
	%r84 = load %ptr, %ptr* %t6
	%r88 = bitcast %ptr %r84 to [0 x %ptr]*
	%r87 = ptrtoint %ptr %r83 to %word
	%r86 = getelementptr [0 x %ptr], [0 x %ptr]* %r88, %word 0, %word %r87
	%r85 = load %ptr, %ptr* %r86
	%r92 = ptrtoint %ptr %r85 to %word
	%r91 = ptrtoint %ptr %r73 to %word
	%r90 = ashr %word %r92, %r91
	%r89 = inttoptr %word %r90 to %ptr
	%r96 = ptrtoint %ptr %r89 to %word
	%r95 = ptrtoint %ptr %r69 to %word
	%r94 = sub %word %r96, %r95
	%r93 = inttoptr %word %r94 to %ptr
	store %ptr %r93, %ptr* %t6
	br label %L926
L925:
	%r97 = load %ptr, %ptr* %t2
	store %ptr %r97, %ptr* %t7
	%r98 = inttoptr %word 0 to %ptr
	%r99 = inttoptr %word 0 to %ptr
	%r100 = load %ptr, %ptr* %t7
	%r104 = bitcast %ptr %r100 to [0 x %ptr]*
	%r103 = ptrtoint %ptr %r99 to %word
	%r102 = getelementptr [0 x %ptr], [0 x %ptr]* %r104, %word 0, %word %r103
	%r101 = load %ptr, %ptr* %r102
	store %ptr %r101, %ptr* %t2
	%r105 = inttoptr %word 1 to %ptr
	%r106 = load %ptr, %ptr* %t6
	%r110 = ptrtoint %ptr %r106 to %word
	%r109 = ptrtoint %ptr %r105 to %word
	%r108 = sub %word %r110, %r109
	%r107 = inttoptr %word %r108 to %ptr
	store %ptr %r107, %ptr* %t6
	br label %L926
L926:
	%r111 = load %ptr, %ptr* %t6
	%r112 = inttoptr %word 0 to %ptr
	%r116 = ptrtoint %ptr %r112 to %word
	%r115 = ptrtoint %ptr %r111 to %word
	%r114 = icmp slt %word %r116, %r115
	%r113 = inttoptr i1 %r114 to %ptr
	%r118 = ptrtoint %ptr %r113 to %word
	%r117 = icmp ne %word %r118, 0
	br i1 %r117, label %L925, label %L927
L927:
	%r119 = load %ptr, %ptr* %t2
	store %ptr %r119, %ptr* %t7
	%r120 = inttoptr %word 0 to %ptr
	%r121 = inttoptr %word 2 to %ptr
	%r122 = load %ptr, %ptr* %t7
	%r126 = bitcast %ptr %r122 to [0 x %ptr]*
	%r125 = ptrtoint %ptr %r121 to %word
	%r124 = getelementptr [0 x %ptr], [0 x %ptr]* %r126, %word 0, %word %r125
	%r123 = load %ptr, %ptr* %r124
	%r127 = inttoptr %word 1 to %ptr
	%r128 = load %ptr, %ptr* %t3
	store %ptr %r128, %ptr* %t7
	%r129 = inttoptr %word 0 to %ptr
	%r130 = inttoptr %word 3 to %ptr
	%r131 = load %ptr, %ptr* %t7
	%r135 = bitcast %ptr %r131 to [0 x %ptr]*
	%r134 = ptrtoint %ptr %r130 to %word
	%r133 = getelementptr [0 x %ptr], [0 x %ptr]* %r135, %word 0, %word %r134
	%r132 = load %ptr, %ptr* %r133
	%r139 = ptrtoint %ptr %r132 to %word
	%r138 = ptrtoint %ptr %r127 to %word
	%r137 = ashr %word %r139, %r138
	%r136 = inttoptr %word %r137 to %ptr
	%r140 = load %ptr, %ptr* %t4
	%r141 = call %ptr @"k/set-array-at"(%ptr %r123, %ptr %r136, %ptr %r140)
	store %ptr %r141, %ptr* %t5
	br label %L924
L924:
	%r142 = load %ptr, %ptr* %t5
	ret %ptr %r142
}
define %ptr @"subr/while"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	store %ptr %r3, %ptr* %t4
	br label %L929
L928:
	%r4 = load %ptr, %ptr* %t4
	store %ptr %r4, %ptr* %t5
	br label %L932
L931:
	%r5 = inttoptr %word 0 to %ptr
	%r6 = load %ptr, %ptr* %t5
	%r10 = bitcast %ptr %r6 to [0 x %ptr]*
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = getelementptr [0 x %ptr], [0 x %ptr]* %r10, %word 0, %word %r9
	%r7 = load %ptr, %ptr* %r8
	%r11 = load %ptr, %ptr* %t2
	%r12 = call %ptr @"k/eval"(%ptr %r7, %ptr %r11)
	br label %L932
L932:
	%r13 = load %ptr, %ptr* %t5
	%r14 = call %ptr @"k/cdr"(%ptr %r13)
	store %ptr %r14, %ptr* %t5
	%r15 = call %ptr @"get/type"(%ptr %r14)
	%r16 = inttoptr %word 19 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r22 = ptrtoint %ptr %r17 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L931, label %L933
L933:
	br label %L929
L929:
	%r23 = load %ptr, %ptr* %t3
	%r24 = load %ptr, %ptr* %t2
	%r25 = call %ptr @"k/eval"(%ptr %r23, %ptr %r24)
	%r27 = ptrtoint %ptr %r25 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L928, label %L930
L930:
	ret %ptr %r25
}
define %ptr @"subr/if"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	%r3 = load %ptr, %ptr* %t2
	%r4 = call %ptr @"k/eval"(%ptr %r2, %ptr %r3)
	%r6 = ptrtoint %ptr %r4 to %word
	%r5 = icmp ne %word %r6, 0
	br i1 %r5, label %L934, label %L935
L934:
	%r7 = load %ptr, %ptr* %t1
	%r8 = call %ptr @"k/cadr"(%ptr %r7)
	%r9 = load %ptr, %ptr* %t2
	%r10 = call %ptr @"k/eval"(%ptr %r8, %ptr %r9)
	store %ptr %r10, %ptr* %t3
	br label %L936
L935:
	%r11 = inttoptr %word 0 to %ptr
	store %ptr %r11, %ptr* %t4
	%r12 = load %ptr, %ptr* %t1
	%r13 = call %ptr @"k/cdr"(%ptr %r12)
	store %ptr %r13, %ptr* %t1
	br label %L938
L937:
	%r14 = inttoptr %word 0 to %ptr
	%r15 = load %ptr, %ptr* %t1
	%r19 = bitcast %ptr %r15 to [0 x %ptr]*
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = getelementptr [0 x %ptr], [0 x %ptr]* %r19, %word 0, %word %r18
	%r16 = load %ptr, %ptr* %r17
	%r20 = load %ptr, %ptr* %t2
	%r21 = call %ptr @"k/eval"(%ptr %r16, %ptr %r20)
	store %ptr %r21, %ptr* %t4
	br label %L938
L938:
	%r22 = load %ptr, %ptr* %t1
	%r23 = call %ptr @"k/cdr"(%ptr %r22)
	store %ptr %r23, %ptr* %t1
	%r24 = call %ptr @"get/type"(%ptr %r23)
	%r25 = inttoptr %word 19 to %ptr
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = icmp eq %word %r29, %r28
	%r26 = inttoptr i1 %r27 to %ptr
	%r31 = ptrtoint %ptr %r26 to %word
	%r30 = icmp ne %word %r31, 0
	br i1 %r30, label %L937, label %L939
L939:
	%r32 = load %ptr, %ptr* %t4
	store %ptr %r32, %ptr* %t3
	br label %L936
L936:
	%r33 = load %ptr, %ptr* %t3
	ret %ptr %r33
}
define %ptr @"subr/or"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t3
	br label %L941
L940:
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t4
	%r3 = inttoptr %word 0 to %ptr
	%r4 = load %ptr, %ptr* %t1
	%r8 = bitcast %ptr %r4 to [0 x %ptr]*
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = getelementptr [0 x %ptr], [0 x %ptr]* %r8, %word 0, %word %r7
	%r5 = load %ptr, %ptr* %r6
	%r9 = load %ptr, %ptr* %t2
	%r10 = call %ptr @"k/eval"(%ptr %r5, %ptr %r9)
	store %ptr %r10, %ptr* %t3
	store %ptr %r10, %ptr* %t4
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L943, label %L944
L944:
	%r18 = load %ptr, %ptr* %t3
	ret %ptr %r18
	store %ptr %r18, %ptr* %t4
	%r20 = inttoptr %word 0 to %ptr
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ptrtoint %ptr %r18 to %word
	%r22 = icmp eq %word %r24, %r23
	%r21 = inttoptr i1 %r22 to %ptr
	%r26 = ptrtoint %ptr %r21 to %word
	%r25 = icmp ne %word %r26, 0
	br i1 %r25, label %L943, label %L945
L945:
	br label %L943
L943:
	%r27 = load %ptr, %ptr* %t4
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t1
	%r33 = bitcast %ptr %r29 to [0 x %ptr]*
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = getelementptr [0 x %ptr], [0 x %ptr]* %r33, %word 0, %word %r32
	%r30 = load %ptr, %ptr* %r31
	store %ptr %r30, %ptr* %t1
	br label %L941
L941:
	%r34 = load %ptr, %ptr* %t1
	%r35 = call %ptr @"get/type"(%ptr %r34)
	%r36 = inttoptr %word 19 to %ptr
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = icmp eq %word %r40, %r39
	%r37 = inttoptr i1 %r38 to %ptr
	%r42 = ptrtoint %ptr %r37 to %word
	%r41 = icmp ne %word %r42, 0
	br i1 %r41, label %L940, label %L942
L942:
	ret %ptr %r37
}
define %ptr @"subr/and"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r1, %ptr* %t3
	br label %L947
L946:
	%r2 = inttoptr %word 0 to %ptr
	store %ptr %r2, %ptr* %t4
	%r3 = inttoptr %word 0 to %ptr
	%r4 = load %ptr, %ptr* %t1
	%r8 = bitcast %ptr %r4 to [0 x %ptr]*
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = getelementptr [0 x %ptr], [0 x %ptr]* %r8, %word 0, %word %r7
	%r5 = load %ptr, %ptr* %r6
	%r9 = load %ptr, %ptr* %t2
	%r10 = call %ptr @"k/eval"(%ptr %r5, %ptr %r9)
	store %ptr %r10, %ptr* %t3
	store %ptr %r10, %ptr* %t4
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L950, label %L949
L950:
	%r18 = inttoptr %word 0 to %ptr
	ret %ptr %r18
	store %ptr %r18, %ptr* %t4
	%r20 = inttoptr %word 0 to %ptr
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ptrtoint %ptr %r18 to %word
	%r22 = icmp eq %word %r24, %r23
	%r21 = inttoptr i1 %r22 to %ptr
	%r26 = ptrtoint %ptr %r21 to %word
	%r25 = icmp ne %word %r26, 0
	br i1 %r25, label %L951, label %L949
L951:
	br label %L949
L949:
	%r27 = load %ptr, %ptr* %t4
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t1
	%r33 = bitcast %ptr %r29 to [0 x %ptr]*
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = getelementptr [0 x %ptr], [0 x %ptr]* %r33, %word 0, %word %r32
	%r30 = load %ptr, %ptr* %r31
	store %ptr %r30, %ptr* %t1
	br label %L947
L947:
	%r34 = load %ptr, %ptr* %t1
	%r35 = call %ptr @"get/type"(%ptr %r34)
	%r36 = inttoptr %word 19 to %ptr
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = icmp eq %word %r40, %r39
	%r37 = inttoptr i1 %r38 to %ptr
	%r42 = ptrtoint %ptr %r37 to %word
	%r41 = icmp ne %word %r42, 0
	br i1 %r41, label %L946, label %L948
L948:
	%r43 = load %ptr, %ptr* %t3
	ret %ptr %r43
}
define %ptr @"subr/quote"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	ret %ptr %r3
}
define %ptr @"subr/not"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	%r5 = ptrtoint %ptr %r3 to %word
	%r4 = icmp ne %word %r5, 0
	br i1 %r4, label %L952, label %L953
L952:
	%r6 = inttoptr %word 0 to %ptr
	store %ptr %r6, %ptr* %t3
	br label %L954
L953:
	%r7 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r7, %ptr* %t3
	br label %L954
L954:
	%r8 = load %ptr, %ptr* %t3
	ret %ptr %r8
}
define %ptr @"subr/fixed"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	%r4 = call %ptr @"new-<fixed>"(%ptr %r3)
	ret %ptr %r4
}
define %ptr @"subr/variable"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/cadr"(%ptr %r4)
	%r6 = load %ptr, %ptr* %t1
	%r7 = call %ptr @"k/caddr"(%ptr %r6)
	%r8 = load %ptr, %ptr* %t1
	%r9 = call %ptr @"k/cadddr"(%ptr %r8)
	%r10 = call %ptr @"new-<variable>"(%ptr %r3, %ptr %r5, %ptr %r7, %ptr %r9)
	ret %ptr %r10
}
@str957 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str958 = private unnamed_addr constant [24 x i8] c"kernel assertion failed\00"
@str959 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"subr/environment"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = load %ptr, %ptr* %t3
	%r6 = call %ptr @"get/type"(%ptr %r5)
	%r7 = inttoptr %word 13 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	store %ptr %r8, %ptr* %t4
	%r12 = inttoptr %word 0 to %ptr
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = ptrtoint %ptr %r8 to %word
	%r14 = icmp eq %word %r16, %r15
	%r13 = inttoptr i1 %r14 to %ptr
	%r18 = ptrtoint %ptr %r13 to %word
	%r17 = icmp ne %word %r18, 0
	br i1 %r17, label %L956, label %L955
L956:
	%r19 = getelementptr [9 x i8], [9 x i8]* @str957, %word 0, %word 0
	%r21 = call i32 (%ptr, ...) @printf(%ptr %r19)
	%r22 = inttoptr %word %r21 to %ptr
	%r23 = getelementptr [24 x i8], [24 x i8]* @str958, %word 0, %word 0
	%r25 = call i32 (%ptr, ...) @printf(%ptr %r23)
	%r26 = inttoptr %word %r25 to %ptr
	%r27 = getelementptr [2 x i8], [2 x i8]* @str959, %word 0, %word 0
	%r29 = call i32 (%ptr, ...) @printf(%ptr %r27)
	%r30 = inttoptr %word %r29 to %ptr
	%r31 = call %ptr @die()
	store %ptr %r31, %ptr* %t4
	%r32 = inttoptr %word 0 to %ptr
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = icmp eq %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	%r38 = ptrtoint %ptr %r33 to %word
	%r37 = icmp ne %word %r38, 0
	br i1 %r37, label %L960, label %L955
L960:
	br label %L955
L955:
	%r39 = load %ptr, %ptr* %t4
	%r40 = load %ptr, %ptr* %t3
	%r41 = inttoptr %word 0 to %ptr
	%r42 = inttoptr %word 1 to %ptr
	%r43 = load %ptr, %ptr* %t3
	store %ptr %r43, %ptr* %t4
	%r44 = inttoptr %word 0 to %ptr
	%r45 = inttoptr %word 2 to %ptr
	%r46 = load %ptr, %ptr* %t4
	%r50 = bitcast %ptr %r46 to [0 x %ptr]*
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = getelementptr [0 x %ptr], [0 x %ptr]* %r50, %word 0, %word %r49
	%r47 = load %ptr, %ptr* %r48
	%r54 = ptrtoint %ptr %r47 to %word
	%r53 = ptrtoint %ptr %r42 to %word
	%r52 = ashr %word %r54, %r53
	%r51 = inttoptr %word %r52 to %ptr
	%r55 = call %ptr @"new-<env>"(%ptr %r40, %ptr %r41, %ptr %r51)
	ret %ptr %r55
}
@str963 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str964 = private unnamed_addr constant [24 x i8] c"kernel assertion failed\00"
@str965 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str969 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str970 = private unnamed_addr constant [24 x i8] c"kernel assertion failed\00"
@str971 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"subr/environment-define"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/cadr"(%ptr %r4)
	store %ptr %r5, %ptr* %t4
	%r6 = load %ptr, %ptr* %t1
	%r7 = call %ptr @"k/caddr"(%ptr %r6)
	store %ptr %r7, %ptr* %t5
	%r8 = inttoptr %word 0 to %ptr
	store %ptr %r8, %ptr* %t6
	%r9 = load %ptr, %ptr* %t3
	%r10 = call %ptr @"get/type"(%ptr %r9)
	%r11 = inttoptr %word 13 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	store %ptr %r12, %ptr* %t6
	%r16 = inttoptr %word 0 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r12 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r22 = ptrtoint %ptr %r17 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L962, label %L961
L962:
	%r23 = getelementptr [9 x i8], [9 x i8]* @str963, %word 0, %word 0
	%r25 = call i32 (%ptr, ...) @printf(%ptr %r23)
	%r26 = inttoptr %word %r25 to %ptr
	%r27 = getelementptr [24 x i8], [24 x i8]* @str964, %word 0, %word 0
	%r29 = call i32 (%ptr, ...) @printf(%ptr %r27)
	%r30 = inttoptr %word %r29 to %ptr
	%r31 = getelementptr [2 x i8], [2 x i8]* @str965, %word 0, %word 0
	%r33 = call i32 (%ptr, ...) @printf(%ptr %r31)
	%r34 = inttoptr %word %r33 to %ptr
	%r35 = call %ptr @die()
	store %ptr %r35, %ptr* %t6
	%r36 = inttoptr %word 0 to %ptr
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = icmp eq %word %r40, %r39
	%r37 = inttoptr i1 %r38 to %ptr
	%r42 = ptrtoint %ptr %r37 to %word
	%r41 = icmp ne %word %r42, 0
	br i1 %r41, label %L966, label %L961
L966:
	br label %L961
L961:
	%r43 = load %ptr, %ptr* %t6
	%r44 = inttoptr %word 0 to %ptr
	store %ptr %r44, %ptr* %t6
	%r45 = load %ptr, %ptr* %t4
	%r46 = call %ptr @"get/type"(%ptr %r45)
	%r47 = inttoptr %word 18 to %ptr
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r46 to %word
	%r49 = icmp eq %word %r51, %r50
	%r48 = inttoptr i1 %r49 to %ptr
	store %ptr %r48, %ptr* %t6
	%r52 = inttoptr %word 0 to %ptr
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r48 to %word
	%r54 = icmp eq %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	%r58 = ptrtoint %ptr %r53 to %word
	%r57 = icmp ne %word %r58, 0
	br i1 %r57, label %L968, label %L967
L968:
	%r59 = getelementptr [9 x i8], [9 x i8]* @str969, %word 0, %word 0
	%r61 = call i32 (%ptr, ...) @printf(%ptr %r59)
	%r62 = inttoptr %word %r61 to %ptr
	%r63 = getelementptr [24 x i8], [24 x i8]* @str970, %word 0, %word 0
	%r65 = call i32 (%ptr, ...) @printf(%ptr %r63)
	%r66 = inttoptr %word %r65 to %ptr
	%r67 = getelementptr [2 x i8], [2 x i8]* @str971, %word 0, %word 0
	%r69 = call i32 (%ptr, ...) @printf(%ptr %r67)
	%r70 = inttoptr %word %r69 to %ptr
	%r71 = call %ptr @die()
	store %ptr %r71, %ptr* %t6
	%r72 = inttoptr %word 0 to %ptr
	%r76 = ptrtoint %ptr %r72 to %word
	%r75 = ptrtoint %ptr %r71 to %word
	%r74 = icmp eq %word %r76, %r75
	%r73 = inttoptr i1 %r74 to %ptr
	%r78 = ptrtoint %ptr %r73 to %word
	%r77 = icmp ne %word %r78, 0
	br i1 %r77, label %L972, label %L967
L972:
	br label %L967
L967:
	%r79 = load %ptr, %ptr* %t6
	%r80 = load %ptr, %ptr* %t3
	store %ptr %r80, %ptr* %t6
	%r81 = inttoptr %word 0 to %ptr
	%r82 = inttoptr %word 3 to %ptr
	%r83 = load %ptr, %ptr* %t6
	%r87 = bitcast %ptr %r83 to [0 x %ptr]*
	%r86 = ptrtoint %ptr %r82 to %word
	%r85 = getelementptr [0 x %ptr], [0 x %ptr]* %r87, %word 0, %word %r86
	%r84 = load %ptr, %ptr* %r85
	store %ptr %r84, %ptr* %t6
	%r88 = inttoptr %word 1 to %ptr
	%r89 = load %ptr, %ptr* %t3
	store %ptr %r89, %ptr* %t7
	%r90 = inttoptr %word 0 to %ptr
	%r91 = inttoptr %word 2 to %ptr
	%r92 = load %ptr, %ptr* %t7
	%r96 = bitcast %ptr %r92 to [0 x %ptr]*
	%r95 = ptrtoint %ptr %r91 to %word
	%r94 = getelementptr [0 x %ptr], [0 x %ptr]* %r96, %word 0, %word %r95
	%r93 = load %ptr, %ptr* %r94
	%r100 = ptrtoint %ptr %r93 to %word
	%r99 = ptrtoint %ptr %r88 to %word
	%r98 = ashr %word %r100, %r99
	%r97 = inttoptr %word %r98 to %ptr
	store %ptr %r97, %ptr* %t7
	%r101 = load %ptr, %ptr* %t4
	%r102 = load %ptr, %ptr* %t5
	%r103 = load %ptr, %ptr* %t3
	%r104 = load %ptr, %ptr* %t7
	%r105 = call %ptr @"new-<variable>"(%ptr %r101, %ptr %r102, %ptr %r103, %ptr %r104)
	store %ptr %r105, %ptr* %t8
	%r107 = getelementptr %ptr, %ptr* %t8, %word 0
	%r106 = bitcast %ptr* %r107 to %ptr
	%r108 = call %ptr @"gc/push-root"(%ptr %r106)
	%r109 = load %ptr, %ptr* %t3
	store %ptr %r109, %ptr* %t9
	%r110 = inttoptr %word 0 to %ptr
	%r111 = inttoptr %word 1 to %ptr
	%r112 = inttoptr %word 1 to %ptr
	%r113 = inttoptr %word 1 to %ptr
	%r114 = load %ptr, %ptr* %t7
	%r118 = ptrtoint %ptr %r114 to %word
	%r117 = ptrtoint %ptr %r113 to %word
	%r116 = add %word %r118, %r117
	%r115 = inttoptr %word %r116 to %ptr
	%r122 = ptrtoint %ptr %r115 to %word
	%r121 = ptrtoint %ptr %r112 to %word
	%r120 = shl %word %r122, %r121
	%r119 = inttoptr %word %r120 to %ptr
	%r126 = ptrtoint %ptr %r119 to %word
	%r125 = ptrtoint %ptr %r111 to %word
	%r124 = add %word %r126, %r125
	%r123 = inttoptr %word %r124 to %ptr
	%r127 = inttoptr %word 2 to %ptr
	%r128 = load %ptr, %ptr* %t9
	%r132 = bitcast %ptr %r128 to [0 x %ptr]*
	%r131 = ptrtoint %ptr %r127 to %word
	%r130 = getelementptr [0 x %ptr], [0 x %ptr]* %r132, %word 0, %word %r131
	store %ptr %r123, %ptr* %r130
	%r129 = bitcast %ptr %r123 to %ptr
	%r133 = load %ptr, %ptr* %t6
	%r134 = load %ptr, %ptr* %t8
	%r135 = call %ptr @"k/array-append"(%ptr %r133, %ptr %r134)
	%r136 = load %ptr, %ptr* %t8
	store %ptr %r136, %ptr* %t9
	%r138 = getelementptr %ptr, %ptr* %t8, %word 0
	%r137 = bitcast %ptr* %r138 to %ptr
	%r139 = call %ptr @"gc/pop-root"(%ptr %r137)
	%r140 = load %ptr, %ptr* %t9
	ret %ptr %r140
}
define %ptr @"subr/-"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 1 to %ptr
	%r9 = load %ptr, %ptr* %t1
	%r13 = bitcast %ptr %r9 to [0 x %ptr]*
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = getelementptr [0 x %ptr], [0 x %ptr]* %r13, %word 0, %word %r12
	%r10 = load %ptr, %ptr* %r11
	store %ptr %r10, %ptr* %t4
	%r14 = load %ptr, %ptr* %t4
	%r15 = call %ptr @"get/type"(%ptr %r14)
	%r16 = inttoptr %word 19 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r22 = ptrtoint %ptr %r17 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L973, label %L974
L973:
	%r23 = inttoptr %word 0 to %ptr
	%r24 = load %ptr, %ptr* %t4
	%r28 = bitcast %ptr %r24 to [0 x %ptr]*
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = getelementptr [0 x %ptr], [0 x %ptr]* %r28, %word 0, %word %r27
	%r25 = load %ptr, %ptr* %r26
	store %ptr %r25, %ptr* %t4
	%r29 = inttoptr %word 0 to %ptr
	%r30 = inttoptr %word 1 to %ptr
	%r31 = inttoptr %word 1 to %ptr
	%r32 = inttoptr %word 1 to %ptr
	%r33 = load %ptr, %ptr* %t4
	%r37 = ptrtoint %ptr %r33 to %word
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ashr %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r38 = inttoptr %word 1 to %ptr
	%r39 = load %ptr, %ptr* %t3
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ashr %word %r43, %r42
	%r40 = inttoptr %word %r41 to %ptr
	%r47 = ptrtoint %ptr %r40 to %word
	%r46 = ptrtoint %ptr %r34 to %word
	%r45 = sub %word %r47, %r46
	%r44 = inttoptr %word %r45 to %ptr
	%r51 = ptrtoint %ptr %r44 to %word
	%r50 = ptrtoint %ptr %r31 to %word
	%r49 = shl %word %r51, %r50
	%r48 = inttoptr %word %r49 to %ptr
	%r55 = ptrtoint %ptr %r48 to %word
	%r54 = ptrtoint %ptr %r30 to %word
	%r53 = add %word %r55, %r54
	%r52 = inttoptr %word %r53 to %ptr
	store %ptr %r52, %ptr* %t5
	br label %L975
L974:
	%r56 = inttoptr %word 0 to %ptr
	%r57 = inttoptr %word 1 to %ptr
	%r58 = inttoptr %word 1 to %ptr
	%r59 = inttoptr %word 1 to %ptr
	%r60 = load %ptr, %ptr* %t3
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = ashr %word %r64, %r63
	%r61 = inttoptr %word %r62 to %ptr
	%r67 = ptrtoint %ptr %r61 to %word
	%r66 = sub nsw %word 0, %r67
	%r65 = inttoptr %word %r66 to %ptr
	%r71 = ptrtoint %ptr %r65 to %word
	%r70 = ptrtoint %ptr %r58 to %word
	%r69 = shl %word %r71, %r70
	%r68 = inttoptr %word %r69 to %ptr
	%r75 = ptrtoint %ptr %r68 to %word
	%r74 = ptrtoint %ptr %r57 to %word
	%r73 = add %word %r75, %r74
	%r72 = inttoptr %word %r73 to %ptr
	store %ptr %r72, %ptr* %t5
	br label %L975
L975:
	%r76 = load %ptr, %ptr* %t5
	ret %ptr %r76
}
define %ptr @"subr/&"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = and %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr/|"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = or %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr/^"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = xor %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr/+"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = add %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr/*"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = mul %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr//"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = sdiv %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr/<<"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = shl %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr/>>"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t4
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t3
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r24 to %word
	%r35 = ashr %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r41 = ptrtoint %ptr %r34 to %word
	%r40 = ptrtoint %ptr %r21 to %word
	%r39 = shl %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	%r45 = ptrtoint %ptr %r38 to %word
	%r44 = ptrtoint %ptr %r20 to %word
	%r43 = add %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	ret %ptr %r42
}
define %ptr @"subr/<"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	store %ptr %r20, %ptr* %t5
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t4
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ashr %word %r26, %r25
	%r23 = inttoptr %word %r24 to %ptr
	%r27 = inttoptr %word 1 to %ptr
	%r28 = load %ptr, %ptr* %t3
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ashr %word %r32, %r31
	%r29 = inttoptr %word %r30 to %ptr
	%r36 = ptrtoint %ptr %r29 to %word
	%r35 = ptrtoint %ptr %r23 to %word
	%r34 = icmp slt %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	store %ptr %r33, %ptr* %t5
	%r37 = inttoptr %word 0 to %ptr
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r33 to %word
	%r39 = icmp eq %word %r41, %r40
	%r38 = inttoptr i1 %r39 to %ptr
	%r43 = ptrtoint %ptr %r38 to %word
	%r42 = icmp ne %word %r43, 0
	br i1 %r42, label %L976, label %L977
L977:
	%r44 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r44, %ptr* %t5
	%r45 = inttoptr %word 0 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = icmp eq %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	%r51 = ptrtoint %ptr %r46 to %word
	%r50 = icmp ne %word %r51, 0
	br i1 %r50, label %L976, label %L978
L978:
	br label %L976
L976:
	%r52 = load %ptr, %ptr* %t5
	ret %ptr %r52
}
define %ptr @"subr/<="(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	store %ptr %r20, %ptr* %t5
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t4
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ashr %word %r26, %r25
	%r23 = inttoptr %word %r24 to %ptr
	%r27 = inttoptr %word 1 to %ptr
	%r28 = load %ptr, %ptr* %t3
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ashr %word %r32, %r31
	%r29 = inttoptr %word %r30 to %ptr
	%r36 = ptrtoint %ptr %r29 to %word
	%r35 = ptrtoint %ptr %r23 to %word
	%r34 = icmp sle %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	store %ptr %r33, %ptr* %t5
	%r37 = inttoptr %word 0 to %ptr
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r33 to %word
	%r39 = icmp eq %word %r41, %r40
	%r38 = inttoptr i1 %r39 to %ptr
	%r43 = ptrtoint %ptr %r38 to %word
	%r42 = icmp ne %word %r43, 0
	br i1 %r42, label %L979, label %L980
L980:
	%r44 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r44, %ptr* %t5
	%r45 = inttoptr %word 0 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = icmp eq %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	%r51 = ptrtoint %ptr %r46 to %word
	%r50 = icmp ne %word %r51, 0
	br i1 %r50, label %L979, label %L981
L981:
	br label %L979
L979:
	%r52 = load %ptr, %ptr* %t5
	ret %ptr %r52
}
define %ptr @"subr/>="(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	store %ptr %r20, %ptr* %t5
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t4
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ashr %word %r26, %r25
	%r23 = inttoptr %word %r24 to %ptr
	%r27 = inttoptr %word 1 to %ptr
	%r28 = load %ptr, %ptr* %t3
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ashr %word %r32, %r31
	%r29 = inttoptr %word %r30 to %ptr
	%r36 = ptrtoint %ptr %r29 to %word
	%r35 = ptrtoint %ptr %r23 to %word
	%r34 = icmp sge %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	store %ptr %r33, %ptr* %t5
	%r37 = inttoptr %word 0 to %ptr
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r33 to %word
	%r39 = icmp eq %word %r41, %r40
	%r38 = inttoptr i1 %r39 to %ptr
	%r43 = ptrtoint %ptr %r38 to %word
	%r42 = icmp ne %word %r43, 0
	br i1 %r42, label %L982, label %L983
L983:
	%r44 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r44, %ptr* %t5
	%r45 = inttoptr %word 0 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = icmp eq %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	%r51 = ptrtoint %ptr %r46 to %word
	%r50 = icmp ne %word %r51, 0
	br i1 %r50, label %L982, label %L984
L984:
	br label %L982
L982:
	%r52 = load %ptr, %ptr* %t5
	ret %ptr %r52
}
define %ptr @"subr/>"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	store %ptr %r20, %ptr* %t5
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t4
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ashr %word %r26, %r25
	%r23 = inttoptr %word %r24 to %ptr
	%r27 = inttoptr %word 1 to %ptr
	%r28 = load %ptr, %ptr* %t3
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = ashr %word %r32, %r31
	%r29 = inttoptr %word %r30 to %ptr
	%r36 = ptrtoint %ptr %r29 to %word
	%r35 = ptrtoint %ptr %r23 to %word
	%r34 = icmp sgt %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	store %ptr %r33, %ptr* %t5
	%r37 = inttoptr %word 0 to %ptr
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r33 to %word
	%r39 = icmp eq %word %r41, %r40
	%r38 = inttoptr i1 %r39 to %ptr
	%r43 = ptrtoint %ptr %r38 to %word
	%r42 = icmp ne %word %r43, 0
	br i1 %r42, label %L985, label %L986
L986:
	%r44 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r44, %ptr* %t5
	%r45 = inttoptr %word 0 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = icmp eq %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	%r51 = ptrtoint %ptr %r46 to %word
	%r50 = icmp ne %word %r51, 0
	br i1 %r50, label %L985, label %L987
L987:
	br label %L985
L985:
	%r52 = load %ptr, %ptr* %t5
	ret %ptr %r52
}
define %ptr @"subr/="(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = load %ptr, %ptr* %t3
	%r20 = call %ptr @"get/type"(%ptr %r19)
	store %ptr %r20, %ptr* %t5
	%r21 = inttoptr %word 6 to %ptr
	%r22 = load %ptr, %ptr* %t5
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L988, label %L989
L988:
	%r29 = inttoptr %word 1 to %ptr
	store %ptr %r29, %ptr* %t7
	%r30 = load %ptr, %ptr* %t4
	%r31 = call %ptr @"get/type"(%ptr %r30)
	%r32 = inttoptr %word 6 to %ptr
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = icmp eq %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	store %ptr %r33, %ptr* %t7
	%r37 = inttoptr %word 0 to %ptr
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r33 to %word
	%r39 = icmp eq %word %r41, %r40
	%r38 = inttoptr i1 %r39 to %ptr
	%r43 = ptrtoint %ptr %r38 to %word
	%r42 = icmp ne %word %r43, 0
	br i1 %r42, label %L991, label %L992
L992:
	%r44 = inttoptr %word 1 to %ptr
	%r45 = load %ptr, %ptr* %t4
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ashr %word %r49, %r48
	%r46 = inttoptr %word %r47 to %ptr
	%r50 = inttoptr %word 1 to %ptr
	%r51 = load %ptr, %ptr* %t3
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = ashr %word %r55, %r54
	%r52 = inttoptr %word %r53 to %ptr
	%r59 = ptrtoint %ptr %r52 to %word
	%r58 = ptrtoint %ptr %r46 to %word
	%r57 = icmp eq %word %r59, %r58
	%r56 = inttoptr i1 %r57 to %ptr
	store %ptr %r56, %ptr* %t7
	%r60 = inttoptr %word 0 to %ptr
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r56 to %word
	%r62 = icmp eq %word %r64, %r63
	%r61 = inttoptr i1 %r62 to %ptr
	%r66 = ptrtoint %ptr %r61 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L991, label %L993
L993:
	%r67 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r67, %ptr* %t7
	%r68 = inttoptr %word 0 to %ptr
	%r72 = ptrtoint %ptr %r68 to %word
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = icmp eq %word %r72, %r71
	%r69 = inttoptr i1 %r70 to %ptr
	%r74 = ptrtoint %ptr %r69 to %word
	%r73 = icmp ne %word %r74, 0
	br i1 %r73, label %L991, label %L994
L994:
	br label %L991
L991:
	%r75 = load %ptr, %ptr* %t7
	store %ptr %r75, %ptr* %t6
	br label %L990
L989:
	%r76 = inttoptr %word 17 to %ptr
	%r77 = load %ptr, %ptr* %t5
	%r81 = ptrtoint %ptr %r77 to %word
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = icmp eq %word %r81, %r80
	%r78 = inttoptr i1 %r79 to %ptr
	%r83 = ptrtoint %ptr %r78 to %word
	%r82 = icmp ne %word %r83, 0
	br i1 %r82, label %L995, label %L996
L995:
	%r84 = inttoptr %word 1 to %ptr
	store %ptr %r84, %ptr* %t8
	%r85 = load %ptr, %ptr* %t4
	%r86 = call %ptr @"get/type"(%ptr %r85)
	%r87 = inttoptr %word 17 to %ptr
	%r91 = ptrtoint %ptr %r87 to %word
	%r90 = ptrtoint %ptr %r86 to %word
	%r89 = icmp eq %word %r91, %r90
	%r88 = inttoptr i1 %r89 to %ptr
	store %ptr %r88, %ptr* %t8
	%r92 = inttoptr %word 0 to %ptr
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = ptrtoint %ptr %r88 to %word
	%r94 = icmp eq %word %r96, %r95
	%r93 = inttoptr i1 %r94 to %ptr
	%r98 = ptrtoint %ptr %r93 to %word
	%r97 = icmp ne %word %r98, 0
	br i1 %r97, label %L998, label %L999
L999:
	%r99 = load %ptr, %ptr* %t3
	store %ptr %r99, %ptr* %t9
	%r100 = inttoptr %word 0 to %ptr
	%r101 = inttoptr %word 1 to %ptr
	%r102 = load %ptr, %ptr* %t9
	%r106 = bitcast %ptr %r102 to [0 x %ptr]*
	%r105 = ptrtoint %ptr %r101 to %word
	%r104 = getelementptr [0 x %ptr], [0 x %ptr]* %r106, %word 0, %word %r105
	%r103 = load %ptr, %ptr* %r104
	%r107 = load %ptr, %ptr* %t4
	store %ptr %r107, %ptr* %t9
	%r108 = inttoptr %word 0 to %ptr
	%r109 = inttoptr %word 1 to %ptr
	%r110 = load %ptr, %ptr* %t9
	%r114 = bitcast %ptr %r110 to [0 x %ptr]*
	%r113 = ptrtoint %ptr %r109 to %word
	%r112 = getelementptr [0 x %ptr], [0 x %ptr]* %r114, %word 0, %word %r113
	%r111 = load %ptr, %ptr* %r112
	%r115 = call i32 @strcmp(%ptr %r103, %ptr %r111)
	%r116 = inttoptr %word %r115 to %ptr
	%r120 = ptrtoint %ptr %r116 to %word
	%r119 = icmp eq %word %r120, 0
	%r118 = zext i1 %r119 to %word
	%r117 = inttoptr %word %r118 to %ptr
	store %ptr %r117, %ptr* %t8
	%r121 = inttoptr %word 0 to %ptr
	%r125 = ptrtoint %ptr %r121 to %word
	%r124 = ptrtoint %ptr %r117 to %word
	%r123 = icmp eq %word %r125, %r124
	%r122 = inttoptr i1 %r123 to %ptr
	%r127 = ptrtoint %ptr %r122 to %word
	%r126 = icmp ne %word %r127, 0
	br i1 %r126, label %L998, label %L1000
L1000:
	%r128 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r128, %ptr* %t8
	%r129 = inttoptr %word 0 to %ptr
	%r133 = ptrtoint %ptr %r129 to %word
	%r132 = ptrtoint %ptr %r128 to %word
	%r131 = icmp eq %word %r133, %r132
	%r130 = inttoptr i1 %r131 to %ptr
	%r135 = ptrtoint %ptr %r130 to %word
	%r134 = icmp ne %word %r135, 0
	br i1 %r134, label %L998, label %L1001
L1001:
	br label %L998
L998:
	%r136 = load %ptr, %ptr* %t8
	store %ptr %r136, %ptr* %t7
	br label %L997
L996:
	%r137 = inttoptr %word 1 to %ptr
	store %ptr %r137, %ptr* %t8
	%r138 = load %ptr, %ptr* %t4
	%r139 = load %ptr, %ptr* %t3
	%r143 = ptrtoint %ptr %r139 to %word
	%r142 = ptrtoint %ptr %r138 to %word
	%r141 = icmp eq %word %r143, %r142
	%r140 = inttoptr i1 %r141 to %ptr
	store %ptr %r140, %ptr* %t8
	%r144 = inttoptr %word 0 to %ptr
	%r148 = ptrtoint %ptr %r144 to %word
	%r147 = ptrtoint %ptr %r140 to %word
	%r146 = icmp eq %word %r148, %r147
	%r145 = inttoptr i1 %r146 to %ptr
	%r150 = ptrtoint %ptr %r145 to %word
	%r149 = icmp ne %word %r150, 0
	br i1 %r149, label %L1002, label %L1003
L1003:
	%r151 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r151, %ptr* %t8
	%r152 = inttoptr %word 0 to %ptr
	%r156 = ptrtoint %ptr %r152 to %word
	%r155 = ptrtoint %ptr %r151 to %word
	%r154 = icmp eq %word %r156, %r155
	%r153 = inttoptr i1 %r154 to %ptr
	%r158 = ptrtoint %ptr %r153 to %word
	%r157 = icmp ne %word %r158, 0
	br i1 %r157, label %L1002, label %L1004
L1004:
	br label %L1002
L1002:
	%r159 = load %ptr, %ptr* %t8
	store %ptr %r159, %ptr* %t7
	br label %L997
L997:
	%r160 = load %ptr, %ptr* %t7
	store %ptr %r160, %ptr* %t6
	br label %L990
L990:
	%r161 = load %ptr, %ptr* %t6
	ret %ptr %r161
}
define %ptr @"subr/!="(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = load %ptr, %ptr* %t3
	%r20 = call %ptr @"get/type"(%ptr %r19)
	store %ptr %r20, %ptr* %t5
	%r21 = inttoptr %word 6 to %ptr
	%r22 = load %ptr, %ptr* %t5
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L1005, label %L1006
L1005:
	%r29 = inttoptr %word 1 to %ptr
	store %ptr %r29, %ptr* %t7
	%r30 = load %ptr, %ptr* %t4
	%r31 = call %ptr @"get/type"(%ptr %r30)
	%r32 = inttoptr %word 6 to %ptr
	%r36 = ptrtoint %ptr %r32 to %word
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = icmp eq %word %r36, %r35
	%r33 = inttoptr i1 %r34 to %ptr
	store %ptr %r33, %ptr* %t7
	%r37 = inttoptr %word 0 to %ptr
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r33 to %word
	%r39 = icmp eq %word %r41, %r40
	%r38 = inttoptr i1 %r39 to %ptr
	%r43 = ptrtoint %ptr %r38 to %word
	%r42 = icmp ne %word %r43, 0
	br i1 %r42, label %L1008, label %L1009
L1009:
	%r44 = inttoptr %word 1 to %ptr
	%r45 = load %ptr, %ptr* %t4
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ashr %word %r49, %r48
	%r46 = inttoptr %word %r47 to %ptr
	%r50 = inttoptr %word 1 to %ptr
	%r51 = load %ptr, %ptr* %t3
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = ptrtoint %ptr %r50 to %word
	%r53 = ashr %word %r55, %r54
	%r52 = inttoptr %word %r53 to %ptr
	%r59 = ptrtoint %ptr %r52 to %word
	%r58 = ptrtoint %ptr %r46 to %word
	%r57 = icmp ne %word %r59, %r58
	%r56 = inttoptr i1 %r57 to %ptr
	store %ptr %r56, %ptr* %t7
	%r60 = inttoptr %word 0 to %ptr
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ptrtoint %ptr %r56 to %word
	%r62 = icmp eq %word %r64, %r63
	%r61 = inttoptr i1 %r62 to %ptr
	%r66 = ptrtoint %ptr %r61 to %word
	%r65 = icmp ne %word %r66, 0
	br i1 %r65, label %L1008, label %L1010
L1010:
	%r67 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r67, %ptr* %t7
	%r68 = inttoptr %word 0 to %ptr
	%r72 = ptrtoint %ptr %r68 to %word
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = icmp eq %word %r72, %r71
	%r69 = inttoptr i1 %r70 to %ptr
	%r74 = ptrtoint %ptr %r69 to %word
	%r73 = icmp ne %word %r74, 0
	br i1 %r73, label %L1008, label %L1011
L1011:
	br label %L1008
L1008:
	%r75 = load %ptr, %ptr* %t7
	store %ptr %r75, %ptr* %t6
	br label %L1007
L1006:
	%r76 = inttoptr %word 17 to %ptr
	%r77 = load %ptr, %ptr* %t5
	%r81 = ptrtoint %ptr %r77 to %word
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = icmp eq %word %r81, %r80
	%r78 = inttoptr i1 %r79 to %ptr
	%r83 = ptrtoint %ptr %r78 to %word
	%r82 = icmp ne %word %r83, 0
	br i1 %r82, label %L1012, label %L1013
L1012:
	%r84 = inttoptr %word 1 to %ptr
	store %ptr %r84, %ptr* %t8
	%r85 = load %ptr, %ptr* %t4
	%r86 = call %ptr @"get/type"(%ptr %r85)
	%r87 = inttoptr %word 17 to %ptr
	%r91 = ptrtoint %ptr %r87 to %word
	%r90 = ptrtoint %ptr %r86 to %word
	%r89 = icmp eq %word %r91, %r90
	%r88 = inttoptr i1 %r89 to %ptr
	store %ptr %r88, %ptr* %t8
	%r92 = inttoptr %word 0 to %ptr
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = ptrtoint %ptr %r88 to %word
	%r94 = icmp eq %word %r96, %r95
	%r93 = inttoptr i1 %r94 to %ptr
	%r98 = ptrtoint %ptr %r93 to %word
	%r97 = icmp ne %word %r98, 0
	br i1 %r97, label %L1015, label %L1016
L1016:
	%r99 = load %ptr, %ptr* %t3
	store %ptr %r99, %ptr* %t9
	%r100 = inttoptr %word 0 to %ptr
	%r101 = inttoptr %word 1 to %ptr
	%r102 = load %ptr, %ptr* %t9
	%r106 = bitcast %ptr %r102 to [0 x %ptr]*
	%r105 = ptrtoint %ptr %r101 to %word
	%r104 = getelementptr [0 x %ptr], [0 x %ptr]* %r106, %word 0, %word %r105
	%r103 = load %ptr, %ptr* %r104
	%r107 = load %ptr, %ptr* %t4
	store %ptr %r107, %ptr* %t9
	%r108 = inttoptr %word 0 to %ptr
	%r109 = inttoptr %word 1 to %ptr
	%r110 = load %ptr, %ptr* %t9
	%r114 = bitcast %ptr %r110 to [0 x %ptr]*
	%r113 = ptrtoint %ptr %r109 to %word
	%r112 = getelementptr [0 x %ptr], [0 x %ptr]* %r114, %word 0, %word %r113
	%r111 = load %ptr, %ptr* %r112
	%r115 = call i32 @strcmp(%ptr %r103, %ptr %r111)
	%r116 = inttoptr %word %r115 to %ptr
	store %ptr %r116, %ptr* %t8
	%r117 = inttoptr %word 0 to %ptr
	%r121 = ptrtoint %ptr %r117 to %word
	%r120 = ptrtoint %ptr %r116 to %word
	%r119 = icmp eq %word %r121, %r120
	%r118 = inttoptr i1 %r119 to %ptr
	%r123 = ptrtoint %ptr %r118 to %word
	%r122 = icmp ne %word %r123, 0
	br i1 %r122, label %L1015, label %L1017
L1017:
	br label %L1015
L1015:
	%r124 = load %ptr, %ptr* %t8
	%r125 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r125, %ptr* %t7
	br label %L1014
L1013:
	%r126 = inttoptr %word 1 to %ptr
	store %ptr %r126, %ptr* %t8
	%r127 = load %ptr, %ptr* %t4
	%r128 = load %ptr, %ptr* %t3
	%r132 = ptrtoint %ptr %r128 to %word
	%r131 = ptrtoint %ptr %r127 to %word
	%r130 = icmp ne %word %r132, %r131
	%r129 = inttoptr i1 %r130 to %ptr
	store %ptr %r129, %ptr* %t8
	%r133 = inttoptr %word 0 to %ptr
	%r137 = ptrtoint %ptr %r133 to %word
	%r136 = ptrtoint %ptr %r129 to %word
	%r135 = icmp eq %word %r137, %r136
	%r134 = inttoptr i1 %r135 to %ptr
	%r139 = ptrtoint %ptr %r134 to %word
	%r138 = icmp ne %word %r139, 0
	br i1 %r138, label %L1018, label %L1019
L1019:
	%r140 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r140, %ptr* %t8
	%r141 = inttoptr %word 0 to %ptr
	%r145 = ptrtoint %ptr %r141 to %word
	%r144 = ptrtoint %ptr %r140 to %word
	%r143 = icmp eq %word %r145, %r144
	%r142 = inttoptr i1 %r143 to %ptr
	%r147 = ptrtoint %ptr %r142 to %word
	%r146 = icmp ne %word %r147, 0
	br i1 %r146, label %L1018, label %L1020
L1020:
	br label %L1018
L1018:
	%r148 = load %ptr, %ptr* %t8
	store %ptr %r148, %ptr* %t7
	br label %L1014
L1014:
	%r149 = load %ptr, %ptr* %t7
	store %ptr %r149, %ptr* %t6
	br label %L1007
L1007:
	%r150 = load %ptr, %ptr* %t6
	ret %ptr %r150
}
define %ptr @"subr/abort"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = call %ptr @print-backtrace()
	%r3 = call %ptr @"libc/flush-streams"()
	call void @abort()
	%r5 = inttoptr %word 0 to %ptr
	ret %ptr %r5
}
@str1023 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str1024 = private unnamed_addr constant [40 x i8] c"argument to subr_exit is not a <long>: \00"
@str1025 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @"subr/exit"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = load %ptr, %ptr* %t3
	%r6 = call %ptr @"get/type"(%ptr %r5)
	%r7 = inttoptr %word 6 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	store %ptr %r8, %ptr* %t4
	%r12 = inttoptr %word 0 to %ptr
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = ptrtoint %ptr %r8 to %word
	%r14 = icmp eq %word %r16, %r15
	%r13 = inttoptr i1 %r14 to %ptr
	%r18 = ptrtoint %ptr %r13 to %word
	%r17 = icmp ne %word %r18, 0
	br i1 %r17, label %L1022, label %L1021
L1022:
	%r19 = getelementptr [9 x i8], [9 x i8]* @str1023, %word 0, %word 0
	%r21 = call i32 (%ptr, ...) @printf(%ptr %r19)
	%r22 = inttoptr %word %r21 to %ptr
	%r23 = getelementptr [40 x i8], [40 x i8]* @str1024, %word 0, %word 0
	%r25 = call i32 (%ptr, ...) @printf(%ptr %r23)
	%r26 = inttoptr %word %r25 to %ptr
	%r27 = load %ptr, %ptr* %t3
	%r28 = call %ptr @"k/print"(%ptr %r27)
	%r29 = getelementptr [2 x i8], [2 x i8]* @str1025, %word 0, %word 0
	%r31 = call i32 (%ptr, ...) @printf(%ptr %r29)
	%r32 = inttoptr %word %r31 to %ptr
	%r33 = call %ptr @die()
	store %ptr %r33, %ptr* %t4
	%r34 = inttoptr %word 0 to %ptr
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = ptrtoint %ptr %r33 to %word
	%r36 = icmp eq %word %r38, %r37
	%r35 = inttoptr i1 %r36 to %ptr
	%r40 = ptrtoint %ptr %r35 to %word
	%r39 = icmp ne %word %r40, 0
	br i1 %r39, label %L1026, label %L1021
L1026:
	br label %L1021
L1021:
	%r41 = load %ptr, %ptr* %t4
	%r42 = call %ptr @"libc/flush-streams"()
	%r43 = inttoptr %word 1 to %ptr
	%r44 = load %ptr, %ptr* %t3
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = ashr %word %r48, %r47
	%r45 = inttoptr %word %r46 to %ptr
	%ffi-cast49 = ptrtoint %ptr %r45 to i32
	call void @exit(i32 %ffi-cast49)
	%r51 = inttoptr %word 0 to %ptr
	ret %ptr %r51
}
@str1027 = private unnamed_addr constant [3 x i8] c"rb\00"
define %ptr @"subr/libc/fopen"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	%r6 = inttoptr %word 1 to %ptr
	%r7 = load %ptr, %ptr* %t4
	%r11 = bitcast %ptr %r7 to [0 x %ptr]*
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = getelementptr [0 x %ptr], [0 x %ptr]* %r11, %word 0, %word %r10
	%r8 = load %ptr, %ptr* %r9
	%r12 = getelementptr [3 x i8], [3 x i8]* @str1027, %word 0, %word 0
	%r14 = call %ptr @fopen(%ptr %r8, %ptr %r12)
	store %ptr %r14, %ptr* %t4
	%r15 = inttoptr %word 1 to %ptr
	store %ptr %r15, %ptr* %t5
	%r16 = load %ptr, %ptr* %t4
	store %ptr %r16, %ptr* %t5
	%r17 = inttoptr %word 0 to %ptr
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp eq %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	%r23 = ptrtoint %ptr %r18 to %word
	%r22 = icmp ne %word %r23, 0
	br i1 %r22, label %L1028, label %L1029
L1029:
	%r24 = load %ptr, %ptr* %t4
	%r25 = call %ptr @"new-<target-vm-pointer>"(%ptr %r24)
	store %ptr %r25, %ptr* %t5
	%r26 = inttoptr %word 0 to %ptr
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = icmp eq %word %r30, %r29
	%r27 = inttoptr i1 %r28 to %ptr
	%r32 = ptrtoint %ptr %r27 to %word
	%r31 = icmp ne %word %r32, 0
	br i1 %r31, label %L1028, label %L1030
L1030:
	br label %L1028
L1028:
	%r33 = load %ptr, %ptr* %t5
	ret %ptr %r33
}
define %ptr @"subr/libc/fclose"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	%r6 = inttoptr %word 0 to %ptr
	%r7 = load %ptr, %ptr* %t4
	%r11 = bitcast %ptr %r7 to [0 x %ptr]*
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = getelementptr [0 x %ptr], [0 x %ptr]* %r11, %word 0, %word %r10
	%r8 = load %ptr, %ptr* %r9
	%r12 = call i32 @fclose(%ptr %r8)
	%r13 = inttoptr %word %r12 to %ptr
	%r14 = inttoptr %word 0 to %ptr
	ret %ptr %r14
}
define %ptr @"subr/libc/fgetc"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	store %ptr %r2, %ptr* %t3
	%r3 = inttoptr %word 0 to %ptr
	store %ptr %r3, %ptr* %t4
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	%r11 = ptrtoint %ptr %r6 to %word
	%r10 = icmp ne %word %r11, 0
	br i1 %r10, label %L1032, label %L1031
L1032:
	%r12 = load %ptr, %ptr* @"var/*input*"
	store %ptr %r12, %ptr* %t5
	%r13 = inttoptr %word 0 to %ptr
	%r14 = inttoptr %word 1 to %ptr
	%r15 = load %ptr, %ptr* %t5
	%r19 = bitcast %ptr %r15 to [0 x %ptr]*
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = getelementptr [0 x %ptr], [0 x %ptr]* %r19, %word 0, %word %r18
	%r16 = load %ptr, %ptr* %r17
	store %ptr %r16, %ptr* %t3
	store %ptr %r16, %ptr* %t4
	%r20 = inttoptr %word 0 to %ptr
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ptrtoint %ptr %r16 to %word
	%r22 = icmp eq %word %r24, %r23
	%r21 = inttoptr i1 %r22 to %ptr
	%r26 = ptrtoint %ptr %r21 to %word
	%r25 = icmp ne %word %r26, 0
	br i1 %r25, label %L1033, label %L1031
L1033:
	br label %L1031
L1031:
	%r27 = load %ptr, %ptr* %t4
	%r28 = load %ptr, %ptr* %t3
	store %ptr %r28, %ptr* %t4
	%r29 = inttoptr %word 0 to %ptr
	%r30 = inttoptr %word 0 to %ptr
	%r31 = load %ptr, %ptr* %t4
	%r35 = bitcast %ptr %r31 to [0 x %ptr]*
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = getelementptr [0 x %ptr], [0 x %ptr]* %r35, %word 0, %word %r34
	%r32 = load %ptr, %ptr* %r33
	%r36 = call i32 @fgetc(%ptr %r32)
	%r37 = inttoptr %word %r36 to %ptr
	store %ptr %r37, %ptr* %t4
	%r38 = inttoptr %word 1 to %ptr
	store %ptr %r38, %ptr* %t5
	%r39 = inttoptr %word 0 to %ptr
	%r40 = load %ptr, %ptr* %t4
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = icmp sge %word %r44, %r43
	%r41 = inttoptr i1 %r42 to %ptr
	store %ptr %r41, %ptr* %t5
	%r45 = inttoptr %word 0 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r41 to %word
	%r47 = icmp eq %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	%r51 = ptrtoint %ptr %r46 to %word
	%r50 = icmp ne %word %r51, 0
	br i1 %r50, label %L1034, label %L1035
L1035:
	%r52 = inttoptr %word 1 to %ptr
	%r53 = inttoptr %word 1 to %ptr
	%r54 = load %ptr, %ptr* %t4
	%r58 = ptrtoint %ptr %r54 to %word
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = shl %word %r58, %r57
	%r55 = inttoptr %word %r56 to %ptr
	%r62 = ptrtoint %ptr %r55 to %word
	%r61 = ptrtoint %ptr %r52 to %word
	%r60 = add %word %r62, %r61
	%r59 = inttoptr %word %r60 to %ptr
	store %ptr %r59, %ptr* %t5
	%r63 = inttoptr %word 0 to %ptr
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r59 to %word
	%r65 = icmp eq %word %r67, %r66
	%r64 = inttoptr i1 %r65 to %ptr
	%r69 = ptrtoint %ptr %r64 to %word
	%r68 = icmp ne %word %r69, 0
	br i1 %r68, label %L1034, label %L1036
L1036:
	br label %L1034
L1034:
	%r70 = load %ptr, %ptr* %t5
	ret %ptr %r70
}
define %ptr @"subr/libc/fputc"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/cadr"(%ptr %r3)
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	store %ptr %r5, %ptr* %t5
	%r6 = load %ptr, %ptr* %t3
	store %ptr %r6, %ptr* %t5
	%r7 = inttoptr %word 0 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	%r13 = ptrtoint %ptr %r8 to %word
	%r12 = icmp ne %word %r13, 0
	br i1 %r12, label %L1038, label %L1037
L1038:
	%r14 = load %ptr, %ptr* @"var/*input*"
	store %ptr %r14, %ptr* %t6
	%r15 = inttoptr %word 0 to %ptr
	%r16 = inttoptr %word 1 to %ptr
	%r17 = load %ptr, %ptr* %t6
	%r21 = bitcast %ptr %r17 to [0 x %ptr]*
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = getelementptr [0 x %ptr], [0 x %ptr]* %r21, %word 0, %word %r20
	%r18 = load %ptr, %ptr* %r19
	store %ptr %r18, %ptr* %t3
	store %ptr %r18, %ptr* %t5
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L1039, label %L1037
L1039:
	br label %L1037
L1037:
	%r29 = load %ptr, %ptr* %t5
	%r30 = inttoptr %word 1 to %ptr
	%r31 = inttoptr %word 1 to %ptr
	%r32 = load %ptr, %ptr* %t3
	store %ptr %r32, %ptr* %t5
	%r33 = inttoptr %word 0 to %ptr
	%r34 = inttoptr %word 0 to %ptr
	%r35 = load %ptr, %ptr* %t5
	%r39 = bitcast %ptr %r35 to [0 x %ptr]*
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = getelementptr [0 x %ptr], [0 x %ptr]* %r39, %word 0, %word %r38
	%r36 = load %ptr, %ptr* %r37
	%r40 = inttoptr %word 1 to %ptr
	%r41 = load %ptr, %ptr* %t4
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ashr %word %r45, %r44
	%r42 = inttoptr %word %r43 to %ptr
	%r46 = call i32 @fputc(%ptr %r36, %ptr %r42)
	%r47 = inttoptr %word %r46 to %ptr
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r31 to %word
	%r49 = shl %word %r51, %r50
	%r48 = inttoptr %word %r49 to %ptr
	%r55 = ptrtoint %ptr %r48 to %word
	%r54 = ptrtoint %ptr %r30 to %word
	%r53 = add %word %r55, %r54
	%r52 = inttoptr %word %r53 to %ptr
	ret %ptr %r52
}
@str1042 = private unnamed_addr constant [36 x i8] c"subr/libc/format: non-string format\00"
@str1058 = private unnamed_addr constant [14 x i8] c"out of memory\00"
@str1069 = private unnamed_addr constant [14 x i8] c"out of memory\00"
define %ptr @"subr/libc/format"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t7 = alloca %ptr
	%t6 = alloca %ptr
	%t5 = alloca %ptr
	%t10 = alloca %ptr
	%t9 = alloca %ptr
	%t8 = alloca %ptr
	%t11 = alloca %ptr
	%t12 = alloca %ptr
	%t13 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/cadr"(%ptr %r4)
	store %ptr %r5, %ptr* %t4
	%r6 = inttoptr %word 0 to %ptr
	store %ptr %r6, %ptr* %t5
	%r7 = load %ptr, %ptr* %t3
	%r8 = call %ptr @"get/type"(%ptr %r7)
	%r9 = inttoptr %word 17 to %ptr
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = icmp eq %word %r13, %r12
	%r10 = inttoptr i1 %r11 to %ptr
	store %ptr %r10, %ptr* %t5
	%r14 = inttoptr %word 0 to %ptr
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = ptrtoint %ptr %r10 to %word
	%r16 = icmp eq %word %r18, %r17
	%r15 = inttoptr i1 %r16 to %ptr
	%r20 = ptrtoint %ptr %r15 to %word
	%r19 = icmp ne %word %r20, 0
	br i1 %r19, label %L1041, label %L1040
L1041:
	%r21 = getelementptr [36 x i8], [36 x i8]* @str1042, %word 0, %word 0
	%r23 = call %ptr @fatal(%ptr %r21)
	store %ptr %r23, %ptr* %t5
	%r24 = inttoptr %word 0 to %ptr
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = icmp eq %word %r28, %r27
	%r25 = inttoptr i1 %r26 to %ptr
	%r30 = ptrtoint %ptr %r25 to %word
	%r29 = icmp ne %word %r30, 0
	br i1 %r29, label %L1043, label %L1040
L1043:
	br label %L1040
L1040:
	%r31 = load %ptr, %ptr* %t5
	%r32 = load %ptr, %ptr* %t3
	store %ptr %r32, %ptr* %t5
	%r33 = inttoptr %word 0 to %ptr
	%r34 = inttoptr %word 1 to %ptr
	%r35 = load %ptr, %ptr* %t5
	%r39 = bitcast %ptr %r35 to [0 x %ptr]*
	%r38 = ptrtoint %ptr %r34 to %word
	%r37 = getelementptr [0 x %ptr], [0 x %ptr]* %r39, %word 0, %word %r38
	%r36 = load %ptr, %ptr* %r37
	store %ptr %r36, %ptr* %t5
	%r40 = load %ptr, %ptr* %t4
	%r41 = call %ptr @"get/type"(%ptr %r40)
	store %ptr %r41, %ptr* %t6
	%r42 = inttoptr %word 0 to %ptr
	store %ptr %r42, %ptr* %t7
	%r43 = inttoptr %word 4 to %ptr
	%r44 = load %ptr, %ptr* %t6
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = icmp eq %word %r48, %r47
	%r45 = inttoptr i1 %r46 to %ptr
	%r50 = ptrtoint %ptr %r45 to %word
	%r49 = icmp ne %word %r50, 0
	br i1 %r49, label %L1044, label %L1045
L1044:
	%r51 = inttoptr %word 0 to %ptr
	store %ptr %r51, %ptr* %t8
	br label %L1046
L1045:
	%r52 = inttoptr %word 6 to %ptr
	%r53 = load %ptr, %ptr* %t6
	%r57 = ptrtoint %ptr %r53 to %word
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = icmp eq %word %r57, %r56
	%r54 = inttoptr i1 %r55 to %ptr
	%r59 = ptrtoint %ptr %r54 to %word
	%r58 = icmp ne %word %r59, 0
	br i1 %r58, label %L1047, label %L1048
L1047:
	%r60 = inttoptr %word 1 to %ptr
	%r61 = load %ptr, %ptr* %t4
	%r65 = ptrtoint %ptr %r61 to %word
	%r64 = ptrtoint %ptr %r60 to %word
	%r63 = ashr %word %r65, %r64
	%r62 = inttoptr %word %r63 to %ptr
	store %ptr %r62, %ptr* %t7
	store %ptr %r62, %ptr* %t9
	br label %L1049
L1048:
	%r66 = inttoptr %word 17 to %ptr
	%r67 = load %ptr, %ptr* %t6
	%r71 = ptrtoint %ptr %r67 to %word
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = icmp eq %word %r71, %r70
	%r68 = inttoptr i1 %r69 to %ptr
	%r73 = ptrtoint %ptr %r68 to %word
	%r72 = icmp ne %word %r73, 0
	br i1 %r72, label %L1050, label %L1051
L1050:
	%r74 = load %ptr, %ptr* %t4
	store %ptr %r74, %ptr* %t11
	%r75 = inttoptr %word 0 to %ptr
	%r76 = inttoptr %word 1 to %ptr
	%r77 = load %ptr, %ptr* %t11
	%r81 = bitcast %ptr %r77 to [0 x %ptr]*
	%r80 = ptrtoint %ptr %r76 to %word
	%r79 = getelementptr [0 x %ptr], [0 x %ptr]* %r81, %word 0, %word %r80
	%r78 = load %ptr, %ptr* %r79
	store %ptr %r78, %ptr* %t7
	store %ptr %r78, %ptr* %t10
	br label %L1052
L1051:
	%r82 = inttoptr %word 18 to %ptr
	%r83 = load %ptr, %ptr* %t6
	%r87 = ptrtoint %ptr %r83 to %word
	%r86 = ptrtoint %ptr %r82 to %word
	%r85 = icmp eq %word %r87, %r86
	%r84 = inttoptr i1 %r85 to %ptr
	%r89 = ptrtoint %ptr %r84 to %word
	%r88 = icmp ne %word %r89, 0
	br i1 %r88, label %L1053, label %L1054
L1053:
	%r90 = load %ptr, %ptr* %t4
	store %ptr %r90, %ptr* %t12
	%r91 = inttoptr %word 0 to %ptr
	%r92 = inttoptr %word 0 to %ptr
	%r93 = load %ptr, %ptr* %t12
	%r97 = bitcast %ptr %r93 to [0 x %ptr]*
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = getelementptr [0 x %ptr], [0 x %ptr]* %r97, %word 0, %word %r96
	%r94 = load %ptr, %ptr* %r95
	store %ptr %r94, %ptr* %t7
	store %ptr %r94, %ptr* %t11
	br label %L1055
L1054:
	%r98 = load %ptr, %ptr* %t4
	store %ptr %r98, %ptr* %t7
	store %ptr %r98, %ptr* %t11
	br label %L1055
L1055:
	%r99 = load %ptr, %ptr* %t11
	store %ptr %r99, %ptr* %t10
	br label %L1052
L1052:
	%r100 = load %ptr, %ptr* %t10
	store %ptr %r100, %ptr* %t9
	br label %L1049
L1049:
	%r101 = load %ptr, %ptr* %t9
	store %ptr %r101, %ptr* %t8
	br label %L1046
L1046:
	%r102 = load %ptr, %ptr* %t8
	%r103 = inttoptr %word 100 to %ptr
	store %ptr %r103, %ptr* %t8
	%r104 = inttoptr %word 0 to %ptr
	store %ptr %r104, %ptr* %t9
	%r105 = inttoptr %word 0 to %ptr
	store %ptr %r105, %ptr* %t10
	%r106 = inttoptr %word 0 to %ptr
	store %ptr %r106, %ptr* %t11
	%r107 = load %ptr, %ptr* %t8
	%ffi-cast108 = ptrtoint %ptr %r107 to i32
	%r109 = call %ptr @malloc(i32 %ffi-cast108)
	store %ptr %r109, %ptr* %t9
	store %ptr %r109, %ptr* %t11
	%r110 = inttoptr %word 0 to %ptr
	%r114 = ptrtoint %ptr %r110 to %word
	%r113 = ptrtoint %ptr %r109 to %word
	%r112 = icmp eq %word %r114, %r113
	%r111 = inttoptr i1 %r112 to %ptr
	%r116 = ptrtoint %ptr %r111 to %word
	%r115 = icmp ne %word %r116, 0
	br i1 %r115, label %L1057, label %L1056
L1057:
	%r117 = getelementptr [14 x i8], [14 x i8]* @str1058, %word 0, %word 0
	ret %ptr %r117
	store %ptr %r117, %ptr* %t11
	%r120 = inttoptr %word 0 to %ptr
	%r124 = ptrtoint %ptr %r120 to %word
	%r123 = ptrtoint %ptr %r117 to %word
	%r122 = icmp eq %word %r124, %r123
	%r121 = inttoptr i1 %r122 to %ptr
	%r126 = ptrtoint %ptr %r121 to %word
	%r125 = icmp ne %word %r126, 0
	br i1 %r125, label %L1059, label %L1056
L1059:
	br label %L1056
L1056:
	%r127 = load %ptr, %ptr* %t11
	br label %L1061
L1060:
	%r128 = load %ptr, %ptr* %t9
	%r129 = load %ptr, %ptr* %t8
	%r130 = load %ptr, %ptr* %t5
	%r131 = load %ptr, %ptr* %t7
	%ffi-cast132 = ptrtoint %ptr %r129 to i32
	%r133 = call i32 (%ptr, i32, %ptr, ...) @snprintf(%ptr %r128, i32 %ffi-cast132, %ptr %r130, %ptr %r131)
	%r134 = inttoptr %word %r133 to %ptr
	store %ptr %r134, %ptr* %t11
	%r135 = inttoptr %word 1 to %ptr
	store %ptr %r135, %ptr* %t12
	%r136 = load %ptr, %ptr* %t11
	%r137 = inttoptr %word 0 to %ptr
	%r141 = ptrtoint %ptr %r137 to %word
	%r140 = ptrtoint %ptr %r136 to %word
	%r139 = icmp sle %word %r141, %r140
	%r138 = inttoptr i1 %r139 to %ptr
	store %ptr %r138, %ptr* %t12
	%r142 = inttoptr %word 0 to %ptr
	%r146 = ptrtoint %ptr %r142 to %word
	%r145 = ptrtoint %ptr %r138 to %word
	%r144 = icmp eq %word %r146, %r145
	%r143 = inttoptr i1 %r144 to %ptr
	%r148 = ptrtoint %ptr %r143 to %word
	%r147 = icmp ne %word %r148, 0
	br i1 %r147, label %L1063, label %L1064
L1064:
	%r149 = load %ptr, %ptr* %t8
	%r150 = load %ptr, %ptr* %t11
	%r154 = ptrtoint %ptr %r150 to %word
	%r153 = ptrtoint %ptr %r149 to %word
	%r152 = icmp slt %word %r154, %r153
	%r151 = inttoptr i1 %r152 to %ptr
	store %ptr %r151, %ptr* %t12
	%r155 = inttoptr %word 0 to %ptr
	%r159 = ptrtoint %ptr %r155 to %word
	%r158 = ptrtoint %ptr %r151 to %word
	%r157 = icmp eq %word %r159, %r158
	%r156 = inttoptr i1 %r157 to %ptr
	%r161 = ptrtoint %ptr %r156 to %word
	%r160 = icmp ne %word %r161, 0
	br i1 %r160, label %L1063, label %L1065
L1065:
	%r162 = load %ptr, %ptr* %t9
	%r163 = call %ptr @"new-<string>-from-cstring"(%ptr %r162)
	store %ptr %r163, %ptr* %t13
	%r164 = load %ptr, %ptr* %t9
	call void @free(%ptr %r164)
	%r166 = inttoptr %word 0 to %ptr
	%r167 = load %ptr, %ptr* %t13
	ret %ptr %r167
	store %ptr %r167, %ptr* %t12
	%r169 = inttoptr %word 0 to %ptr
	%r173 = ptrtoint %ptr %r169 to %word
	%r172 = ptrtoint %ptr %r167 to %word
	%r171 = icmp eq %word %r173, %r172
	%r170 = inttoptr i1 %r171 to %ptr
	%r175 = ptrtoint %ptr %r170 to %word
	%r174 = icmp ne %word %r175, 0
	br i1 %r174, label %L1063, label %L1066
L1066:
	br label %L1063
L1063:
	%r176 = load %ptr, %ptr* %t12
	%r177 = inttoptr %word 2 to %ptr
	%r178 = load %ptr, %ptr* %t8
	%r182 = ptrtoint %ptr %r178 to %word
	%r181 = ptrtoint %ptr %r177 to %word
	%r180 = mul %word %r182, %r181
	%r179 = inttoptr %word %r180 to %ptr
	store %ptr %r179, %ptr* %t8
	%r183 = inttoptr %word 0 to %ptr
	store %ptr %r183, %ptr* %t11
	%r184 = load %ptr, %ptr* %t9
	%r185 = load %ptr, %ptr* %t8
	%ffi-cast186 = ptrtoint %ptr %r185 to i32
	%r187 = call %ptr @realloc(%ptr %r184, i32 %ffi-cast186)
	store %ptr %r187, %ptr* %t10
	store %ptr %r187, %ptr* %t11
	%r188 = inttoptr %word 0 to %ptr
	%r192 = ptrtoint %ptr %r188 to %word
	%r191 = ptrtoint %ptr %r187 to %word
	%r190 = icmp eq %word %r192, %r191
	%r189 = inttoptr i1 %r190 to %ptr
	%r194 = ptrtoint %ptr %r189 to %word
	%r193 = icmp ne %word %r194, 0
	br i1 %r193, label %L1068, label %L1067
L1068:
	%r195 = load %ptr, %ptr* %t9
	call void @free(%ptr %r195)
	%r197 = inttoptr %word 0 to %ptr
	%r198 = getelementptr [14 x i8], [14 x i8]* @str1069, %word 0, %word 0
	ret %ptr %r198
	store %ptr %r198, %ptr* %t11
	%r201 = inttoptr %word 0 to %ptr
	%r205 = ptrtoint %ptr %r201 to %word
	%r204 = ptrtoint %ptr %r198 to %word
	%r203 = icmp eq %word %r205, %r204
	%r202 = inttoptr i1 %r203 to %ptr
	%r207 = ptrtoint %ptr %r202 to %word
	%r206 = icmp ne %word %r207, 0
	br i1 %r206, label %L1070, label %L1067
L1070:
	br label %L1067
L1067:
	%r208 = load %ptr, %ptr* %t11
	%r209 = load %ptr, %ptr* %t10
	store %ptr %r209, %ptr* %t9
	br label %L1061
L1061:
	%r210 = inttoptr %word 1 to %ptr
	%r212 = ptrtoint %ptr %r210 to %word
	%r211 = icmp ne %word %r212, 0
	br i1 %r211, label %L1060, label %L1062
L1062:
	ret %ptr %r210
}
define %ptr @"subr/repl-stream"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	store %ptr %r2, %ptr* %t3
	%r3 = inttoptr %word 0 to %ptr
	store %ptr %r3, %ptr* %t4
	%r4 = load %ptr, %ptr* %t3
	store %ptr %r4, %ptr* %t4
	%r5 = inttoptr %word 0 to %ptr
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	%r11 = ptrtoint %ptr %r6 to %word
	%r10 = icmp ne %word %r11, 0
	br i1 %r10, label %L1072, label %L1071
L1072:
	%r12 = load %ptr, %ptr* @"var/*input*"
	store %ptr %r12, %ptr* %t5
	%r13 = inttoptr %word 0 to %ptr
	%r14 = inttoptr %word 1 to %ptr
	%r15 = load %ptr, %ptr* %t5
	%r19 = bitcast %ptr %r15 to [0 x %ptr]*
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = getelementptr [0 x %ptr], [0 x %ptr]* %r19, %word 0, %word %r18
	%r16 = load %ptr, %ptr* %r17
	store %ptr %r16, %ptr* %t3
	store %ptr %r16, %ptr* %t4
	%r20 = inttoptr %word 0 to %ptr
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ptrtoint %ptr %r16 to %word
	%r22 = icmp eq %word %r24, %r23
	%r21 = inttoptr i1 %r22 to %ptr
	%r26 = ptrtoint %ptr %r21 to %word
	%r25 = icmp ne %word %r26, 0
	br i1 %r25, label %L1073, label %L1071
L1073:
	br label %L1071
L1071:
	%r27 = load %ptr, %ptr* %t4
	%r28 = load %ptr, %ptr* %t3
	store %ptr %r28, %ptr* %t4
	%r29 = inttoptr %word 0 to %ptr
	%r30 = inttoptr %word 0 to %ptr
	%r31 = load %ptr, %ptr* %t4
	%r35 = bitcast %ptr %r31 to [0 x %ptr]*
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = getelementptr [0 x %ptr], [0 x %ptr]* %r35, %word 0, %word %r34
	%r32 = load %ptr, %ptr* %r33
	%r36 = call %ptr @"k/repl-stream"(%ptr %r32)
	ret %ptr %r36
}
define %ptr @"subr/dump"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	br label %L1075
L1074:
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r6 = bitcast %ptr %r2 to [0 x %ptr]*
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = getelementptr [0 x %ptr], [0 x %ptr]* %r6, %word 0, %word %r5
	%r3 = load %ptr, %ptr* %r4
	%r7 = call %ptr @"k/dump"(%ptr %r3)
	%r8 = inttoptr %word 1 to %ptr
	%r9 = load %ptr, %ptr* %t1
	%r13 = bitcast %ptr %r9 to [0 x %ptr]*
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = getelementptr [0 x %ptr], [0 x %ptr]* %r13, %word 0, %word %r12
	%r10 = load %ptr, %ptr* %r11
	store %ptr %r10, %ptr* %t1
	br label %L1075
L1075:
	%r14 = load %ptr, %ptr* %t1
	%r15 = call %ptr @"get/type"(%ptr %r14)
	%r16 = inttoptr %word 19 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r22 = ptrtoint %ptr %r17 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L1074, label %L1076
L1076:
	ret %ptr %r17
}
define %ptr @"subr/print"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	br label %L1078
L1077:
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r6 = bitcast %ptr %r2 to [0 x %ptr]*
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = getelementptr [0 x %ptr], [0 x %ptr]* %r6, %word 0, %word %r5
	%r3 = load %ptr, %ptr* %r4
	%r7 = call %ptr @"k/print"(%ptr %r3)
	%r8 = inttoptr %word 1 to %ptr
	%r9 = load %ptr, %ptr* %t1
	%r13 = bitcast %ptr %r9 to [0 x %ptr]*
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = getelementptr [0 x %ptr], [0 x %ptr]* %r13, %word 0, %word %r12
	%r10 = load %ptr, %ptr* %r11
	store %ptr %r10, %ptr* %t1
	br label %L1078
L1078:
	%r14 = load %ptr, %ptr* %t1
	%r15 = call %ptr @"get/type"(%ptr %r14)
	%r16 = inttoptr %word 19 to %ptr
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = icmp eq %word %r20, %r19
	%r17 = inttoptr i1 %r18 to %ptr
	%r22 = ptrtoint %ptr %r17 to %word
	%r21 = icmp ne %word %r22, 0
	br i1 %r21, label %L1077, label %L1079
L1079:
	ret %ptr %r17
}
@str1086 = private unnamed_addr constant [3 x i8] c"%s\00"
@str1090 = private unnamed_addr constant [3 x i8] c"%s\00"
@str1094 = private unnamed_addr constant [3 x i8] c"%d\00"
@str1095 = private unnamed_addr constant [34 x i8] c"<unable to print {%p} of type %d>\00"
define %ptr @"subr/warn"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	br label %L1081
L1080:
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r6 = bitcast %ptr %r2 to [0 x %ptr]*
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = getelementptr [0 x %ptr], [0 x %ptr]* %r6, %word 0, %word %r5
	%r3 = load %ptr, %ptr* %r4
	store %ptr %r3, %ptr* %t3
	%r7 = load %ptr, %ptr* %t3
	%r8 = call %ptr @"get/type"(%ptr %r7)
	store %ptr %r8, %ptr* %t4
	%r9 = inttoptr %word 17 to %ptr
	%r10 = load %ptr, %ptr* %t4
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = icmp eq %word %r14, %r13
	%r11 = inttoptr i1 %r12 to %ptr
	%r16 = ptrtoint %ptr %r11 to %word
	%r15 = icmp ne %word %r16, 0
	br i1 %r15, label %L1083, label %L1084
L1083:
	%r17 = load %ptr, %ptr* @"libc/stderr"
	%r18 = getelementptr [3 x i8], [3 x i8]* @str1086, %word 0, %word 0
	%r20 = load %ptr, %ptr* %t3
	store %ptr %r20, %ptr* %t6
	%r21 = inttoptr %word 0 to %ptr
	%r22 = inttoptr %word 1 to %ptr
	%r23 = load %ptr, %ptr* %t6
	%r27 = bitcast %ptr %r23 to [0 x %ptr]*
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = getelementptr [0 x %ptr], [0 x %ptr]* %r27, %word 0, %word %r26
	%r24 = load %ptr, %ptr* %r25
	%r28 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r17, %ptr %r18, %ptr %r24)
	%r29 = inttoptr %word %r28 to %ptr
	store %ptr %r29, %ptr* %t5
	br label %L1085
L1084:
	%r30 = inttoptr %word 18 to %ptr
	%r31 = load %ptr, %ptr* %t4
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = icmp eq %word %r35, %r34
	%r32 = inttoptr i1 %r33 to %ptr
	%r37 = ptrtoint %ptr %r32 to %word
	%r36 = icmp ne %word %r37, 0
	br i1 %r36, label %L1087, label %L1088
L1087:
	%r38 = load %ptr, %ptr* @"libc/stderr"
	%r39 = getelementptr [3 x i8], [3 x i8]* @str1090, %word 0, %word 0
	%r41 = load %ptr, %ptr* %t3
	store %ptr %r41, %ptr* %t7
	%r42 = inttoptr %word 0 to %ptr
	%r43 = inttoptr %word 0 to %ptr
	%r44 = load %ptr, %ptr* %t7
	%r48 = bitcast %ptr %r44 to [0 x %ptr]*
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = getelementptr [0 x %ptr], [0 x %ptr]* %r48, %word 0, %word %r47
	%r45 = load %ptr, %ptr* %r46
	%r49 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r38, %ptr %r39, %ptr %r45)
	%r50 = inttoptr %word %r49 to %ptr
	store %ptr %r50, %ptr* %t6
	br label %L1089
L1088:
	%r51 = inttoptr %word 6 to %ptr
	%r52 = load %ptr, %ptr* %t4
	%r56 = ptrtoint %ptr %r52 to %word
	%r55 = ptrtoint %ptr %r51 to %word
	%r54 = icmp eq %word %r56, %r55
	%r53 = inttoptr i1 %r54 to %ptr
	%r58 = ptrtoint %ptr %r53 to %word
	%r57 = icmp ne %word %r58, 0
	br i1 %r57, label %L1091, label %L1092
L1091:
	%r59 = load %ptr, %ptr* @"libc/stderr"
	%r60 = getelementptr [3 x i8], [3 x i8]* @str1094, %word 0, %word 0
	%r62 = inttoptr %word 1 to %ptr
	%r63 = load %ptr, %ptr* %t3
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r62 to %word
	%r65 = ashr %word %r67, %r66
	%r64 = inttoptr %word %r65 to %ptr
	%r68 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r59, %ptr %r60, %ptr %r64)
	%r69 = inttoptr %word %r68 to %ptr
	store %ptr %r69, %ptr* %t7
	br label %L1093
L1092:
	%r70 = load %ptr, %ptr* @"libc/stderr"
	%r71 = getelementptr [34 x i8], [34 x i8]* @str1095, %word 0, %word 0
	%r73 = load %ptr, %ptr* %t3
	%r74 = load %ptr, %ptr* %t4
	%r75 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r70, %ptr %r71, %ptr %r73, %ptr %r74)
	%r76 = inttoptr %word %r75 to %ptr
	store %ptr %r76, %ptr* %t7
	br label %L1093
L1093:
	%r77 = load %ptr, %ptr* %t7
	store %ptr %r77, %ptr* %t6
	br label %L1089
L1089:
	%r78 = load %ptr, %ptr* %t6
	store %ptr %r78, %ptr* %t5
	br label %L1085
L1085:
	%r79 = load %ptr, %ptr* %t5
	%r80 = inttoptr %word 1 to %ptr
	%r81 = load %ptr, %ptr* %t1
	%r85 = bitcast %ptr %r81 to [0 x %ptr]*
	%r84 = ptrtoint %ptr %r80 to %word
	%r83 = getelementptr [0 x %ptr], [0 x %ptr]* %r85, %word 0, %word %r84
	%r82 = load %ptr, %ptr* %r83
	store %ptr %r82, %ptr* %t1
	br label %L1081
L1081:
	%r86 = load %ptr, %ptr* %t1
	%r87 = call %ptr @"get/type"(%ptr %r86)
	%r88 = inttoptr %word 19 to %ptr
	%r92 = ptrtoint %ptr %r88 to %word
	%r91 = ptrtoint %ptr %r87 to %word
	%r90 = icmp eq %word %r92, %r91
	%r89 = inttoptr i1 %r90 to %ptr
	%r94 = ptrtoint %ptr %r89 to %word
	%r93 = icmp ne %word %r94, 0
	br i1 %r93, label %L1080, label %L1082
L1082:
	ret %ptr %r89
}
define %ptr @"subr/apply"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/cadr"(%ptr %r4)
	%r6 = load %ptr, %ptr* %t2
	%r7 = call %ptr @"k/apply"(%ptr %r3, %ptr %r5, %ptr %r6)
	ret %ptr %r7
}
define %ptr @"subr/eval"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	store %ptr %r1, %ptr* %t3
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/cadr"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	%r10 = ptrtoint %ptr %r5 to %word
	%r9 = icmp ne %word %r10, 0
	br i1 %r9, label %L1097, label %L1096
L1097:
	%r11 = load %ptr, %ptr* @"*module*"
	store %ptr %r11, %ptr* %t4
	%r12 = inttoptr %word 0 to %ptr
	%r13 = inttoptr %word 1 to %ptr
	%r14 = load %ptr, %ptr* %t4
	%r18 = bitcast %ptr %r14 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = load %ptr, %ptr* %t4
	%r25 = bitcast %ptr %r21 to [0 x %ptr]*
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = getelementptr [0 x %ptr], [0 x %ptr]* %r25, %word 0, %word %r24
	%r22 = load %ptr, %ptr* %r23
	%r26 = inttoptr %word 1 to %ptr
	%r27 = inttoptr %word 0 to %ptr
	%r28 = call %ptr @"new-<env>"(%ptr %r22, %ptr %r26, %ptr %r27)
	store %ptr %r28, %ptr* %t3
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	%r35 = ptrtoint %ptr %r30 to %word
	%r34 = icmp ne %word %r35, 0
	br i1 %r34, label %L1098, label %L1096
L1098:
	br label %L1096
L1096:
	%r36 = load %ptr, %ptr* %t3
	store %ptr %r36, %ptr* %t3
	%r38 = getelementptr %ptr, %ptr* %t3, %word 0
	%r37 = bitcast %ptr* %r38 to %ptr
	%r39 = call %ptr @"gc/push-root"(%ptr %r37)
	%r40 = load %ptr, %ptr* %t1
	%r41 = call %ptr @"k/car"(%ptr %r40)
	%r42 = load %ptr, %ptr* %t3
	%r43 = call %ptr @"k/expand-encode-eval"(%ptr %r41, %ptr %r42)
	store %ptr %r43, %ptr* %t4
	%r45 = getelementptr %ptr, %ptr* %t3, %word 0
	%r44 = bitcast %ptr* %r45 to %ptr
	%r46 = call %ptr @"gc/pop-root"(%ptr %r44)
	%r47 = load %ptr, %ptr* %t4
	ret %ptr %r47
}
define %ptr @"subr/encode"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	%r3 = inttoptr %word 0 to %ptr
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/cadr"(%ptr %r4)
	store %ptr %r5, %ptr* %t3
	%r6 = inttoptr %word 0 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = icmp ne %word %r12, 0
	br i1 %r11, label %L1100, label %L1099
L1100:
	%r13 = load %ptr, %ptr* %t2
	store %ptr %r13, %ptr* %t4
	%r14 = inttoptr %word 0 to %ptr
	%r15 = inttoptr %word 1 to %ptr
	%r16 = load %ptr, %ptr* %t4
	%r20 = bitcast %ptr %r16 to [0 x %ptr]*
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = getelementptr [0 x %ptr], [0 x %ptr]* %r20, %word 0, %word %r19
	%r17 = load %ptr, %ptr* %r18
	store %ptr %r17, %ptr* %t3
	%r21 = inttoptr %word 0 to %ptr
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r25, %r24
	%r22 = inttoptr i1 %r23 to %ptr
	%r27 = ptrtoint %ptr %r22 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L1101, label %L1099
L1101:
	br label %L1099
L1099:
	%r28 = load %ptr, %ptr* %t3
	%r29 = call %ptr @"k/encode"(%ptr %r2, %ptr %r28)
	ret %ptr %r29
}
define %ptr @"subr/expand"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	%r3 = inttoptr %word 0 to %ptr
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/cadr"(%ptr %r4)
	store %ptr %r5, %ptr* %t3
	%r6 = inttoptr %word 0 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = icmp ne %word %r12, 0
	br i1 %r11, label %L1103, label %L1102
L1103:
	%r13 = load %ptr, %ptr* %t2
	store %ptr %r13, %ptr* %t4
	%r14 = inttoptr %word 0 to %ptr
	%r15 = inttoptr %word 1 to %ptr
	%r16 = load %ptr, %ptr* %t4
	%r20 = bitcast %ptr %r16 to [0 x %ptr]*
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = getelementptr [0 x %ptr], [0 x %ptr]* %r20, %word 0, %word %r19
	%r17 = load %ptr, %ptr* %r18
	store %ptr %r17, %ptr* %t3
	%r21 = inttoptr %word 0 to %ptr
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r17 to %word
	%r23 = icmp eq %word %r25, %r24
	%r22 = inttoptr i1 %r23 to %ptr
	%r27 = ptrtoint %ptr %r22 to %word
	%r26 = icmp ne %word %r27, 0
	br i1 %r26, label %L1104, label %L1102
L1104:
	br label %L1102
L1102:
	%r28 = load %ptr, %ptr* %t3
	%r29 = call %ptr @"k/expand"(%ptr %r2, %ptr %r28)
	ret %ptr %r29
}
define %ptr @"subr/cons"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/cadr"(%ptr %r3)
	%r5 = call %ptr @"new-<pair>"(%ptr %r2, %ptr %r4)
	ret %ptr %r5
}
define %ptr @"subr/string"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/car"(%ptr %r3)
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 6 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	store %ptr %r7, %ptr* %t3
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L1105, label %L1106
L1106:
	%r18 = inttoptr %word 1 to %ptr
	%r19 = inttoptr %word 0 to %ptr
	%r20 = load %ptr, %ptr* %t1
	%r24 = bitcast %ptr %r20 to [0 x %ptr]*
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = getelementptr [0 x %ptr], [0 x %ptr]* %r24, %word 0, %word %r23
	%r21 = load %ptr, %ptr* %r22
	%r28 = ptrtoint %ptr %r21 to %word
	%r27 = ptrtoint %ptr %r18 to %word
	%r26 = ashr %word %r28, %r27
	%r25 = inttoptr %word %r26 to %ptr
	store %ptr %r25, %ptr* %t3
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r25 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	%r35 = ptrtoint %ptr %r30 to %word
	%r34 = icmp ne %word %r35, 0
	br i1 %r34, label %L1105, label %L1107
L1107:
	br label %L1105
L1105:
	%r36 = load %ptr, %ptr* %t3
	%r37 = call %ptr @"new-<string>-of-length"(%ptr %r36)
	ret %ptr %r37
}
define %ptr @"subr/array"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 1 to %ptr
	store %ptr %r1, %ptr* %t3
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	%r4 = call %ptr @"get/type"(%ptr %r3)
	%r5 = inttoptr %word 6 to %ptr
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = icmp eq %word %r9, %r8
	%r6 = inttoptr i1 %r7 to %ptr
	store %ptr %r6, %ptr* %t3
	%r10 = inttoptr %word 0 to %ptr
	%r14 = ptrtoint %ptr %r10 to %word
	%r13 = ptrtoint %ptr %r6 to %word
	%r12 = icmp eq %word %r14, %r13
	%r11 = inttoptr i1 %r12 to %ptr
	%r16 = ptrtoint %ptr %r11 to %word
	%r15 = icmp ne %word %r16, 0
	br i1 %r15, label %L1108, label %L1109
L1109:
	%r17 = inttoptr %word 1 to %ptr
	%r18 = inttoptr %word 0 to %ptr
	%r19 = load %ptr, %ptr* %t1
	%r23 = bitcast %ptr %r19 to [0 x %ptr]*
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = getelementptr [0 x %ptr], [0 x %ptr]* %r23, %word 0, %word %r22
	%r20 = load %ptr, %ptr* %r21
	%r27 = ptrtoint %ptr %r20 to %word
	%r26 = ptrtoint %ptr %r17 to %word
	%r25 = ashr %word %r27, %r26
	%r24 = inttoptr %word %r25 to %ptr
	store %ptr %r24, %ptr* %t3
	%r28 = inttoptr %word 0 to %ptr
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r24 to %word
	%r30 = icmp eq %word %r32, %r31
	%r29 = inttoptr i1 %r30 to %ptr
	%r34 = ptrtoint %ptr %r29 to %word
	%r33 = icmp ne %word %r34, 0
	br i1 %r33, label %L1108, label %L1110
L1110:
	br label %L1108
L1108:
	%r35 = load %ptr, %ptr* %t3
	%r36 = call %ptr @"new-<array>"(%ptr %r35)
	ret %ptr %r36
}
define %ptr @"subr/form"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = call %ptr @"k/car"(%ptr %r1)
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/cadr"(%ptr %r3)
	%r5 = call %ptr @"new-<form>"(%ptr %r2, %ptr %r4)
	ret %ptr %r5
}
define %ptr @"subr/allocate"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 0 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t3
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ashr %word %r26, %r25
	%r23 = inttoptr %word %r24 to %ptr
	%r27 = inttoptr %word 4 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t4
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ashr %word %r33, %r32
	%r30 = inttoptr %word %r31 to %ptr
	%r37 = ptrtoint %ptr %r30 to %word
	%r36 = ptrtoint %ptr %r27 to %word
	%r35 = mul %word %r37, %r36
	%r34 = inttoptr %word %r35 to %ptr
	%r38 = call %ptr @"%new-object"(%ptr %r23, %ptr %r34)
	ret %ptr %r38
}
define %ptr @"subr/type-of"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	%r8 = ptrtoint %ptr %r4 to %word
	%r7 = ptrtoint %ptr %r3 to %word
	%r6 = icmp eq %word %r8, %r7
	%r5 = inttoptr i1 %r6 to %ptr
	%r10 = ptrtoint %ptr %r5 to %word
	%r9 = icmp ne %word %r10, 0
	br i1 %r9, label %L1111, label %L1112
L1112:
	%r11 = inttoptr %word 1 to %ptr
	%r12 = inttoptr %word 1 to %ptr
	%r13 = load %ptr, %ptr* %t1
	%r14 = call %ptr @"k/car"(%ptr %r13)
	%r15 = call %ptr @"get/type"(%ptr %r14)
	%r19 = ptrtoint %ptr %r15 to %word
	%r18 = ptrtoint %ptr %r12 to %word
	%r17 = shl %word %r19, %r18
	%r16 = inttoptr %word %r17 to %ptr
	%r23 = ptrtoint %ptr %r16 to %word
	%r22 = ptrtoint %ptr %r11 to %word
	%r21 = add %word %r23, %r22
	%r20 = inttoptr %word %r21 to %ptr
	store %ptr %r20, %ptr* %t3
	%r24 = inttoptr %word 0 to %ptr
	%r28 = ptrtoint %ptr %r24 to %word
	%r27 = ptrtoint %ptr %r20 to %word
	%r26 = icmp eq %word %r28, %r27
	%r25 = inttoptr i1 %r26 to %ptr
	%r30 = ptrtoint %ptr %r25 to %word
	%r29 = icmp ne %word %r30, 0
	br i1 %r29, label %L1111, label %L1113
L1113:
	br label %L1111
L1111:
	%r31 = load %ptr, %ptr* %t3
	ret %ptr %r31
}
define %ptr @"subr/string?"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/car"(%ptr %r3)
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 17 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	store %ptr %r7, %ptr* %t3
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L1114, label %L1115
L1115:
	%r18 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r18, %ptr* %t3
	%r19 = inttoptr %word 0 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = icmp eq %word %r23, %r22
	%r20 = inttoptr i1 %r21 to %ptr
	%r25 = ptrtoint %ptr %r20 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L1114, label %L1116
L1116:
	br label %L1114
L1114:
	%r26 = load %ptr, %ptr* %t3
	ret %ptr %r26
}
define %ptr @"subr/symbol?"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/car"(%ptr %r3)
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 18 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	store %ptr %r7, %ptr* %t3
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L1117, label %L1118
L1118:
	%r18 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r18, %ptr* %t3
	%r19 = inttoptr %word 0 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = icmp eq %word %r23, %r22
	%r20 = inttoptr i1 %r21 to %ptr
	%r25 = ptrtoint %ptr %r20 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L1117, label %L1119
L1119:
	br label %L1117
L1117:
	%r26 = load %ptr, %ptr* %t3
	ret %ptr %r26
}
define %ptr @"subr/pair?"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/car"(%ptr %r3)
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 19 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	store %ptr %r7, %ptr* %t3
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L1120, label %L1121
L1121:
	%r18 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r18, %ptr* %t3
	%r19 = inttoptr %word 0 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = icmp eq %word %r23, %r22
	%r20 = inttoptr i1 %r21 to %ptr
	%r25 = ptrtoint %ptr %r20 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L1120, label %L1122
L1122:
	br label %L1120
L1120:
	%r26 = load %ptr, %ptr* %t3
	ret %ptr %r26
}
define %ptr @"subr/array?"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	store %ptr %r2, %ptr* %t3
	%r3 = load %ptr, %ptr* %t1
	%r4 = call %ptr @"k/car"(%ptr %r3)
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 7 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	store %ptr %r7, %ptr* %t3
	%r11 = inttoptr %word 0 to %ptr
	%r15 = ptrtoint %ptr %r11 to %word
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = icmp eq %word %r15, %r14
	%r12 = inttoptr i1 %r13 to %ptr
	%r17 = ptrtoint %ptr %r12 to %word
	%r16 = icmp ne %word %r17, 0
	br i1 %r16, label %L1123, label %L1124
L1124:
	%r18 = load %ptr, %ptr* @"symbol/t"
	store %ptr %r18, %ptr* %t3
	%r19 = inttoptr %word 0 to %ptr
	%r23 = ptrtoint %ptr %r19 to %word
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = icmp eq %word %r23, %r22
	%r20 = inttoptr i1 %r21 to %ptr
	%r25 = ptrtoint %ptr %r20 to %word
	%r24 = icmp ne %word %r25, 0
	br i1 %r24, label %L1123, label %L1125
L1125:
	br label %L1123
L1123:
	%r26 = load %ptr, %ptr* %t3
	ret %ptr %r26
}
define %ptr @"subr/car"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	%r4 = call %ptr @"k/car"(%ptr %r3)
	ret %ptr %r4
}
define %ptr @"subr/cdr"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	%r4 = call %ptr @"k/cdr"(%ptr %r3)
	ret %ptr %r4
}
define %ptr @"subr/set-car"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 1 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = load %ptr, %ptr* %t3
	%r6 = call %ptr @"get/type"(%ptr %r5)
	%r7 = inttoptr %word 19 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	store %ptr %r8, %ptr* %t4
	%r12 = inttoptr %word 0 to %ptr
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = ptrtoint %ptr %r8 to %word
	%r14 = icmp eq %word %r16, %r15
	%r13 = inttoptr i1 %r14 to %ptr
	%r18 = ptrtoint %ptr %r13 to %word
	%r17 = icmp ne %word %r18, 0
	br i1 %r17, label %L1126, label %L1127
L1127:
	%r19 = load %ptr, %ptr* %t3
	store %ptr %r19, %ptr* %t5
	%r20 = inttoptr %word 0 to %ptr
	%r21 = load %ptr, %ptr* %t1
	%r22 = call %ptr @"k/cadr"(%ptr %r21)
	%r23 = inttoptr %word 0 to %ptr
	%r24 = load %ptr, %ptr* %t5
	%r28 = bitcast %ptr %r24 to [0 x %ptr]*
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = getelementptr [0 x %ptr], [0 x %ptr]* %r28, %word 0, %word %r27
	store %ptr %r22, %ptr* %r26
	%r25 = bitcast %ptr %r22 to %ptr
	store %ptr %r25, %ptr* %t4
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r25 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	%r35 = ptrtoint %ptr %r30 to %word
	%r34 = icmp ne %word %r35, 0
	br i1 %r34, label %L1126, label %L1128
L1128:
	br label %L1126
L1126:
	%r36 = load %ptr, %ptr* %t4
	ret %ptr %r36
}
define %ptr @"subr/set-cdr"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 1 to %ptr
	store %ptr %r4, %ptr* %t4
	%r5 = load %ptr, %ptr* %t3
	%r6 = call %ptr @"get/type"(%ptr %r5)
	%r7 = inttoptr %word 19 to %ptr
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = icmp eq %word %r11, %r10
	%r8 = inttoptr i1 %r9 to %ptr
	store %ptr %r8, %ptr* %t4
	%r12 = inttoptr %word 0 to %ptr
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = ptrtoint %ptr %r8 to %word
	%r14 = icmp eq %word %r16, %r15
	%r13 = inttoptr i1 %r14 to %ptr
	%r18 = ptrtoint %ptr %r13 to %word
	%r17 = icmp ne %word %r18, 0
	br i1 %r17, label %L1129, label %L1130
L1130:
	%r19 = load %ptr, %ptr* %t3
	store %ptr %r19, %ptr* %t5
	%r20 = inttoptr %word 0 to %ptr
	%r21 = load %ptr, %ptr* %t1
	%r22 = call %ptr @"k/cadr"(%ptr %r21)
	%r23 = inttoptr %word 1 to %ptr
	%r24 = load %ptr, %ptr* %t5
	%r28 = bitcast %ptr %r24 to [0 x %ptr]*
	%r27 = ptrtoint %ptr %r23 to %word
	%r26 = getelementptr [0 x %ptr], [0 x %ptr]* %r28, %word 0, %word %r27
	store %ptr %r22, %ptr* %r26
	%r25 = bitcast %ptr %r22 to %ptr
	store %ptr %r25, %ptr* %t4
	%r29 = inttoptr %word 0 to %ptr
	%r33 = ptrtoint %ptr %r29 to %word
	%r32 = ptrtoint %ptr %r25 to %word
	%r31 = icmp eq %word %r33, %r32
	%r30 = inttoptr i1 %r31 to %ptr
	%r35 = ptrtoint %ptr %r30 to %word
	%r34 = icmp ne %word %r35, 0
	br i1 %r34, label %L1129, label %L1131
L1131:
	br label %L1129
L1129:
	%r36 = load %ptr, %ptr* %t4
	ret %ptr %r36
}
define %ptr @"subr/oop-at"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = load %ptr, %ptr* %t4
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ashr %word %r25, %r24
	%r22 = inttoptr %word %r23 to %ptr
	%r26 = load %ptr, %ptr* %t3
	%r30 = bitcast %ptr %r26 to [0 x %ptr]*
	%r29 = ptrtoint %ptr %r22 to %word
	%r28 = getelementptr [0 x %ptr], [0 x %ptr]* %r30, %word 0, %word %r29
	%r27 = load %ptr, %ptr* %r28
	ret %ptr %r27
}
define %ptr @"subr/set-oop-at"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r30 = bitcast %ptr %r23 to [0 x %ptr]*
	%r29 = ptrtoint %ptr %r20 to %word
	%r28 = getelementptr [0 x %ptr], [0 x %ptr]* %r30, %word 0, %word %r29
	%r27 = load %ptr, %ptr* %r28
	%r34 = bitcast %ptr %r27 to [0 x %ptr]*
	%r33 = ptrtoint %ptr %r19 to %word
	%r32 = getelementptr [0 x %ptr], [0 x %ptr]* %r34, %word 0, %word %r33
	%r31 = load %ptr, %ptr* %r32
	store %ptr %r31, %ptr* %t5
	%r35 = inttoptr %word 0 to %ptr
	%r36 = load %ptr, %ptr* %t5
	%r37 = inttoptr %word 1 to %ptr
	%r38 = load %ptr, %ptr* %t4
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ashr %word %r42, %r41
	%r39 = inttoptr %word %r40 to %ptr
	%r43 = load %ptr, %ptr* %t3
	%r47 = bitcast %ptr %r43 to [0 x %ptr]*
	%r46 = ptrtoint %ptr %r39 to %word
	%r45 = getelementptr [0 x %ptr], [0 x %ptr]* %r47, %word 0, %word %r46
	store %ptr %r36, %ptr* %r45
	%r44 = bitcast %ptr %r36 to %ptr
	ret %ptr %r44
}
define %ptr @"subr/array-length"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 1 to %ptr
	%r3 = inttoptr %word 1 to %ptr
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/car"(%ptr %r4)
	%r6 = call %ptr @"k/array-length"(%ptr %r5)
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r3 to %word
	%r8 = shl %word %r10, %r9
	%r7 = inttoptr %word %r8 to %ptr
	%r14 = ptrtoint %ptr %r7 to %word
	%r13 = ptrtoint %ptr %r2 to %word
	%r12 = add %word %r14, %r13
	%r11 = inttoptr %word %r12 to %ptr
	ret %ptr %r11
}
define %ptr @"subr/array-at"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = load %ptr, %ptr* %t3
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t4
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ashr %word %r26, %r25
	%r23 = inttoptr %word %r24 to %ptr
	%r27 = call %ptr @"k/array-at"(%ptr %r20, %ptr %r23)
	ret %ptr %r27
}
define %ptr @"subr/set-array-at"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r30 = bitcast %ptr %r23 to [0 x %ptr]*
	%r29 = ptrtoint %ptr %r20 to %word
	%r28 = getelementptr [0 x %ptr], [0 x %ptr]* %r30, %word 0, %word %r29
	%r27 = load %ptr, %ptr* %r28
	%r34 = bitcast %ptr %r27 to [0 x %ptr]*
	%r33 = ptrtoint %ptr %r19 to %word
	%r32 = getelementptr [0 x %ptr], [0 x %ptr]* %r34, %word 0, %word %r33
	%r31 = load %ptr, %ptr* %r32
	store %ptr %r31, %ptr* %t5
	%r35 = inttoptr %word 0 to %ptr
	%r36 = load %ptr, %ptr* %t3
	%r37 = inttoptr %word 1 to %ptr
	%r38 = load %ptr, %ptr* %t4
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ashr %word %r42, %r41
	%r39 = inttoptr %word %r40 to %ptr
	%r43 = load %ptr, %ptr* %t5
	%r44 = call %ptr @"k/set-array-at"(%ptr %r36, %ptr %r39, %ptr %r43)
	ret %ptr %r44
}
define %ptr @"subr/array-insert"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r30 = bitcast %ptr %r23 to [0 x %ptr]*
	%r29 = ptrtoint %ptr %r20 to %word
	%r28 = getelementptr [0 x %ptr], [0 x %ptr]* %r30, %word 0, %word %r29
	%r27 = load %ptr, %ptr* %r28
	%r34 = bitcast %ptr %r27 to [0 x %ptr]*
	%r33 = ptrtoint %ptr %r19 to %word
	%r32 = getelementptr [0 x %ptr], [0 x %ptr]* %r34, %word 0, %word %r33
	%r31 = load %ptr, %ptr* %r32
	store %ptr %r31, %ptr* %t5
	%r35 = inttoptr %word 0 to %ptr
	%r36 = load %ptr, %ptr* %t3
	%r37 = inttoptr %word 1 to %ptr
	%r38 = load %ptr, %ptr* %t4
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ashr %word %r42, %r41
	%r39 = inttoptr %word %r40 to %ptr
	%r43 = load %ptr, %ptr* %t5
	%r44 = call %ptr @"k/array-insert"(%ptr %r36, %ptr %r39, %ptr %r43)
	ret %ptr %r44
}
define %ptr @"subr/string-length"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	%r5 = load %ptr, %ptr* %t3
	store %ptr %r5, %ptr* %t4
	%r6 = inttoptr %word 0 to %ptr
	%r7 = inttoptr %word 0 to %ptr
	%r8 = load %ptr, %ptr* %t4
	%r12 = bitcast %ptr %r8 to [0 x %ptr]*
	%r11 = ptrtoint %ptr %r7 to %word
	%r10 = getelementptr [0 x %ptr], [0 x %ptr]* %r12, %word 0, %word %r11
	%r9 = load %ptr, %ptr* %r10
	ret %ptr %r9
}
define %ptr @"subr/string-at"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = load %ptr, %ptr* %t4
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = ptrtoint %ptr %r20 to %word
	%r23 = ashr %word %r25, %r24
	%r22 = inttoptr %word %r23 to %ptr
	store %ptr %r22, %ptr* %t5
	%r26 = inttoptr %word 1 to %ptr
	store %ptr %r26, %ptr* %t6
	%r27 = load %ptr, %ptr* %t5
	%r28 = inttoptr %word 0 to %ptr
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = ptrtoint %ptr %r27 to %word
	%r30 = icmp sle %word %r32, %r31
	%r29 = inttoptr i1 %r30 to %ptr
	store %ptr %r29, %ptr* %t6
	%r33 = inttoptr %word 0 to %ptr
	%r37 = ptrtoint %ptr %r33 to %word
	%r36 = ptrtoint %ptr %r29 to %word
	%r35 = icmp eq %word %r37, %r36
	%r34 = inttoptr i1 %r35 to %ptr
	%r39 = ptrtoint %ptr %r34 to %word
	%r38 = icmp ne %word %r39, 0
	br i1 %r38, label %L1132, label %L1133
L1133:
	%r40 = load %ptr, %ptr* %t3
	%r41 = call %ptr @"k/string-length"(%ptr %r40)
	%r42 = load %ptr, %ptr* %t5
	%r46 = ptrtoint %ptr %r42 to %word
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = icmp slt %word %r46, %r45
	%r43 = inttoptr i1 %r44 to %ptr
	store %ptr %r43, %ptr* %t6
	%r47 = inttoptr %word 0 to %ptr
	%r51 = ptrtoint %ptr %r47 to %word
	%r50 = ptrtoint %ptr %r43 to %word
	%r49 = icmp eq %word %r51, %r50
	%r48 = inttoptr i1 %r49 to %ptr
	%r53 = ptrtoint %ptr %r48 to %word
	%r52 = icmp ne %word %r53, 0
	br i1 %r52, label %L1132, label %L1134
L1134:
	%r54 = inttoptr %word 1 to %ptr
	%r55 = inttoptr %word 1 to %ptr
	%r56 = load %ptr, %ptr* %t5
	%r57 = load %ptr, %ptr* %t3
	store %ptr %r57, %ptr* %t7
	%r58 = inttoptr %word 0 to %ptr
	%r59 = inttoptr %word 1 to %ptr
	%r60 = load %ptr, %ptr* %t7
	%r64 = bitcast %ptr %r60 to [0 x %ptr]*
	%r63 = ptrtoint %ptr %r59 to %word
	%r62 = getelementptr [0 x %ptr], [0 x %ptr]* %r64, %word 0, %word %r63
	%r61 = load %ptr, %ptr* %r62
	%r69 = bitcast %ptr %r61 to [0 x i8]*
	%r68 = ptrtoint %ptr %r56 to %word
	%r67 = getelementptr [0 x i8], [0 x i8]* %r69, %word 0, %word %r68
	%r66 = load i8, i8* %r67
	%r65 = inttoptr i8 %r66 to %ptr
	%r73 = ptrtoint %ptr %r65 to %word
	%r72 = ptrtoint %ptr %r55 to %word
	%r71 = shl %word %r73, %r72
	%r70 = inttoptr %word %r71 to %ptr
	%r77 = ptrtoint %ptr %r70 to %word
	%r76 = ptrtoint %ptr %r54 to %word
	%r75 = add %word %r77, %r76
	%r74 = inttoptr %word %r75 to %ptr
	store %ptr %r74, %ptr* %t6
	%r78 = inttoptr %word 0 to %ptr
	%r82 = ptrtoint %ptr %r78 to %word
	%r81 = ptrtoint %ptr %r74 to %word
	%r80 = icmp eq %word %r82, %r81
	%r79 = inttoptr i1 %r80 to %ptr
	%r84 = ptrtoint %ptr %r79 to %word
	%r83 = icmp ne %word %r84, 0
	br i1 %r83, label %L1132, label %L1135
L1135:
	br label %L1132
L1132:
	%r85 = load %ptr, %ptr* %t6
	ret %ptr %r85
}
define %ptr @"subr/set-string-at"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	%r7 = bitcast %ptr %r3 to [0 x %ptr]*
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = getelementptr [0 x %ptr], [0 x %ptr]* %r7, %word 0, %word %r6
	%r4 = load %ptr, %ptr* %r5
	store %ptr %r4, %ptr* %t3
	%r8 = inttoptr %word 0 to %ptr
	%r9 = inttoptr %word 1 to %ptr
	%r10 = load %ptr, %ptr* %t1
	%r14 = bitcast %ptr %r10 to [0 x %ptr]*
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = getelementptr [0 x %ptr], [0 x %ptr]* %r14, %word 0, %word %r13
	%r11 = load %ptr, %ptr* %r12
	%r18 = bitcast %ptr %r11 to [0 x %ptr]*
	%r17 = ptrtoint %ptr %r8 to %word
	%r16 = getelementptr [0 x %ptr], [0 x %ptr]* %r18, %word 0, %word %r17
	%r15 = load %ptr, %ptr* %r16
	store %ptr %r15, %ptr* %t4
	%r19 = inttoptr %word 0 to %ptr
	%r20 = inttoptr %word 1 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t1
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r30 = bitcast %ptr %r23 to [0 x %ptr]*
	%r29 = ptrtoint %ptr %r20 to %word
	%r28 = getelementptr [0 x %ptr], [0 x %ptr]* %r30, %word 0, %word %r29
	%r27 = load %ptr, %ptr* %r28
	%r34 = bitcast %ptr %r27 to [0 x %ptr]*
	%r33 = ptrtoint %ptr %r19 to %word
	%r32 = getelementptr [0 x %ptr], [0 x %ptr]* %r34, %word 0, %word %r33
	%r31 = load %ptr, %ptr* %r32
	store %ptr %r31, %ptr* %t5
	%r35 = inttoptr %word 0 to %ptr
	%r36 = inttoptr %word 1 to %ptr
	%r37 = load %ptr, %ptr* %t4
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ashr %word %r41, %r40
	%r38 = inttoptr %word %r39 to %ptr
	store %ptr %r38, %ptr* %t6
	%r42 = inttoptr %word 1 to %ptr
	store %ptr %r42, %ptr* %t7
	%r43 = load %ptr, %ptr* %t6
	%r44 = inttoptr %word 0 to %ptr
	%r48 = ptrtoint %ptr %r44 to %word
	%r47 = ptrtoint %ptr %r43 to %word
	%r46 = icmp sle %word %r48, %r47
	%r45 = inttoptr i1 %r46 to %ptr
	store %ptr %r45, %ptr* %t7
	%r49 = inttoptr %word 0 to %ptr
	%r53 = ptrtoint %ptr %r49 to %word
	%r52 = ptrtoint %ptr %r45 to %word
	%r51 = icmp eq %word %r53, %r52
	%r50 = inttoptr i1 %r51 to %ptr
	%r55 = ptrtoint %ptr %r50 to %word
	%r54 = icmp ne %word %r55, 0
	br i1 %r54, label %L1136, label %L1137
L1137:
	%r56 = load %ptr, %ptr* %t3
	%r57 = call %ptr @"k/string-length"(%ptr %r56)
	%r58 = load %ptr, %ptr* %t6
	%r62 = ptrtoint %ptr %r58 to %word
	%r61 = ptrtoint %ptr %r57 to %word
	%r60 = icmp slt %word %r62, %r61
	%r59 = inttoptr i1 %r60 to %ptr
	store %ptr %r59, %ptr* %t7
	%r63 = inttoptr %word 0 to %ptr
	%r67 = ptrtoint %ptr %r63 to %word
	%r66 = ptrtoint %ptr %r59 to %word
	%r65 = icmp eq %word %r67, %r66
	%r64 = inttoptr i1 %r65 to %ptr
	%r69 = ptrtoint %ptr %r64 to %word
	%r68 = icmp ne %word %r69, 0
	br i1 %r68, label %L1136, label %L1138
L1138:
	%r70 = inttoptr %word 1 to %ptr
	%r71 = load %ptr, %ptr* %t5
	%r75 = ptrtoint %ptr %r71 to %word
	%r74 = ptrtoint %ptr %r70 to %word
	%r73 = ashr %word %r75, %r74
	%r72 = inttoptr %word %r73 to %ptr
	%r76 = load %ptr, %ptr* %t6
	%r77 = load %ptr, %ptr* %t3
	store %ptr %r77, %ptr* %t8
	%r78 = inttoptr %word 0 to %ptr
	%r79 = inttoptr %word 1 to %ptr
	%r80 = load %ptr, %ptr* %t8
	%r84 = bitcast %ptr %r80 to [0 x %ptr]*
	%r83 = ptrtoint %ptr %r79 to %word
	%r82 = getelementptr [0 x %ptr], [0 x %ptr]* %r84, %word 0, %word %r83
	%r81 = load %ptr, %ptr* %r82
	%r90 = bitcast %ptr %r81 to [0 x i8]*
	%r89 = ptrtoint %ptr %r76 to %word
	%r88 = getelementptr [0 x i8], [0 x i8]* %r90, %word 0, %word %r89
	%r87 = ptrtoint %ptr %r72 to i8
	store i8 %r87, i8* %r88
	%r86 = zext i8 %r87 to %word
	%r85 = inttoptr %word %r86 to %ptr
	%r91 = load %ptr, %ptr* %t5
	store %ptr %r91, %ptr* %t7
	%r92 = inttoptr %word 0 to %ptr
	%r96 = ptrtoint %ptr %r92 to %word
	%r95 = ptrtoint %ptr %r91 to %word
	%r94 = icmp eq %word %r96, %r95
	%r93 = inttoptr i1 %r94 to %ptr
	%r98 = ptrtoint %ptr %r93 to %word
	%r97 = icmp ne %word %r98, 0
	br i1 %r97, label %L1136, label %L1139
L1139:
	br label %L1136
L1136:
	%r99 = load %ptr, %ptr* %t7
	ret %ptr %r99
}
define %ptr @"subr/string->symbol"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 18 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = icmp ne %word %r12, 0
	br i1 %r11, label %L1140, label %L1141
L1140:
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t4
	br label %L1142
L1141:
	%r14 = inttoptr %word 1 to %ptr
	store %ptr %r14, %ptr* %t5
	%r15 = load %ptr, %ptr* %t3
	%r16 = call %ptr @"get/type"(%ptr %r15)
	%r17 = inttoptr %word 17 to %ptr
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp eq %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t5
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L1143, label %L1144
L1144:
	%r29 = load %ptr, %ptr* %t3
	store %ptr %r29, %ptr* %t6
	%r30 = inttoptr %word 0 to %ptr
	%r31 = inttoptr %word 1 to %ptr
	%r32 = load %ptr, %ptr* %t6
	%r36 = bitcast %ptr %r32 to [0 x %ptr]*
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = getelementptr [0 x %ptr], [0 x %ptr]* %r36, %word 0, %word %r35
	%r33 = load %ptr, %ptr* %r34
	%r37 = call %ptr @intern(%ptr %r33)
	store %ptr %r37, %ptr* %t5
	%r38 = inttoptr %word 0 to %ptr
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = icmp eq %word %r42, %r41
	%r39 = inttoptr i1 %r40 to %ptr
	%r44 = ptrtoint %ptr %r39 to %word
	%r43 = icmp ne %word %r44, 0
	br i1 %r43, label %L1143, label %L1145
L1145:
	br label %L1143
L1143:
	%r45 = load %ptr, %ptr* %t5
	store %ptr %r45, %ptr* %t4
	br label %L1142
L1142:
	%r46 = load %ptr, %ptr* %t4
	ret %ptr %r46
}
define %ptr @"subr/symbol->string"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 17 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = icmp ne %word %r12, 0
	br i1 %r11, label %L1146, label %L1147
L1146:
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t4
	br label %L1148
L1147:
	%r14 = inttoptr %word 1 to %ptr
	store %ptr %r14, %ptr* %t5
	%r15 = load %ptr, %ptr* %t3
	%r16 = call %ptr @"get/type"(%ptr %r15)
	%r17 = inttoptr %word 18 to %ptr
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp eq %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t5
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L1149, label %L1150
L1150:
	%r29 = load %ptr, %ptr* %t3
	store %ptr %r29, %ptr* %t6
	%r30 = inttoptr %word 0 to %ptr
	%r31 = inttoptr %word 0 to %ptr
	%r32 = load %ptr, %ptr* %t6
	%r36 = bitcast %ptr %r32 to [0 x %ptr]*
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = getelementptr [0 x %ptr], [0 x %ptr]* %r36, %word 0, %word %r35
	%r33 = load %ptr, %ptr* %r34
	%r37 = call %ptr @"new-<string>-from-cstring"(%ptr %r33)
	store %ptr %r37, %ptr* %t5
	%r38 = inttoptr %word 0 to %ptr
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = icmp eq %word %r42, %r41
	%r39 = inttoptr i1 %r40 to %ptr
	%r44 = ptrtoint %ptr %r39 to %word
	%r43 = icmp ne %word %r44, 0
	br i1 %r43, label %L1149, label %L1151
L1151:
	br label %L1149
L1149:
	%r45 = load %ptr, %ptr* %t5
	store %ptr %r45, %ptr* %t4
	br label %L1148
L1148:
	%r46 = load %ptr, %ptr* %t4
	ret %ptr %r46
}
@str1157 = private unnamed_addr constant [4 x i8] c"%ld\00"
define %ptr @"subr/long->string"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t3
	%r5 = call %ptr @"get/type"(%ptr %r4)
	%r6 = inttoptr %word 17 to %ptr
	%r10 = ptrtoint %ptr %r6 to %word
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = icmp eq %word %r10, %r9
	%r7 = inttoptr i1 %r8 to %ptr
	%r12 = ptrtoint %ptr %r7 to %word
	%r11 = icmp ne %word %r12, 0
	br i1 %r11, label %L1152, label %L1153
L1152:
	%r13 = load %ptr, %ptr* %t3
	store %ptr %r13, %ptr* %t4
	br label %L1154
L1153:
	%r14 = inttoptr %word 1 to %ptr
	store %ptr %r14, %ptr* %t5
	%r15 = load %ptr, %ptr* %t3
	%r16 = call %ptr @"get/type"(%ptr %r15)
	%r17 = inttoptr %word 6 to %ptr
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = ptrtoint %ptr %r16 to %word
	%r19 = icmp eq %word %r21, %r20
	%r18 = inttoptr i1 %r19 to %ptr
	store %ptr %r18, %ptr* %t5
	%r22 = inttoptr %word 0 to %ptr
	%r26 = ptrtoint %ptr %r22 to %word
	%r25 = ptrtoint %ptr %r18 to %word
	%r24 = icmp eq %word %r26, %r25
	%r23 = inttoptr i1 %r24 to %ptr
	%r28 = ptrtoint %ptr %r23 to %word
	%r27 = icmp ne %word %r28, 0
	br i1 %r27, label %L1155, label %L1156
L1156:
	%r29 = inttoptr %word 32 to %ptr
	%ffi-cast30 = ptrtoint %ptr %r29 to i32
	%r31 = call %ptr @malloc(i32 %ffi-cast30)
	store %ptr %r31, %ptr* %t6
	%r32 = load %ptr, %ptr* %t6
	%r33 = getelementptr [4 x i8], [4 x i8]* @str1157, %word 0, %word 0
	%r35 = inttoptr %word 1 to %ptr
	%r36 = load %ptr, %ptr* %t3
	%r40 = ptrtoint %ptr %r36 to %word
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = ashr %word %r40, %r39
	%r37 = inttoptr %word %r38 to %ptr
	%r41 = call i32 (%ptr, %ptr, ...) @sprintf(%ptr %r32, %ptr %r33, %ptr %r37)
	%r42 = inttoptr %word %r41 to %ptr
	%r43 = load %ptr, %ptr* %t6
	%r44 = call %ptr @"new-<string>-from-cstring"(%ptr %r43)
	store %ptr %r44, %ptr* %t7
	%r45 = load %ptr, %ptr* %t6
	call void @free(%ptr %r45)
	%r47 = inttoptr %word 0 to %ptr
	%r48 = load %ptr, %ptr* %t7
	store %ptr %r48, %ptr* %t5
	%r49 = inttoptr %word 0 to %ptr
	%r53 = ptrtoint %ptr %r49 to %word
	%r52 = ptrtoint %ptr %r48 to %word
	%r51 = icmp eq %word %r53, %r52
	%r50 = inttoptr i1 %r51 to %ptr
	%r55 = ptrtoint %ptr %r50 to %word
	%r54 = icmp ne %word %r55, 0
	br i1 %r54, label %L1155, label %L1158
L1158:
	br label %L1155
L1155:
	%r56 = load %ptr, %ptr* %t5
	store %ptr %r56, %ptr* %t4
	br label %L1154
L1154:
	%r57 = load %ptr, %ptr* %t4
	ret %ptr %r57
}
@str1167 = private unnamed_addr constant [28 x i8] c"read: non-String argument: \00"
@str1169 = private unnamed_addr constant [2 x i8] c"r\00"
define %ptr @"subr/read"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = load %ptr, %ptr* %t1
	%r2 = inttoptr %word 0 to %ptr
	%r6 = ptrtoint %ptr %r2 to %word
	%r5 = ptrtoint %ptr %r1 to %word
	%r4 = icmp eq %word %r6, %r5
	%r3 = inttoptr i1 %r4 to %ptr
	%r8 = ptrtoint %ptr %r3 to %word
	%r7 = icmp ne %word %r8, 0
	br i1 %r7, label %L1159, label %L1160
L1159:
	%r9 = load %ptr, %ptr* @"libc/stdin"
	%r10 = call %ptr @"k/read"(%ptr %r9)
	store %ptr %r10, %ptr* %t4
	%r11 = inttoptr %word 1 to %ptr
	store %ptr %r11, %ptr* %t5
	%r12 = load %ptr, %ptr* %t4
	%r13 = load %ptr, %ptr* @"k/+done+"
	%r17 = ptrtoint %ptr %r13 to %word
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = icmp eq %word %r17, %r16
	%r14 = inttoptr i1 %r15 to %ptr
	store %ptr %r14, %ptr* %t5
	%r18 = inttoptr %word 0 to %ptr
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = ptrtoint %ptr %r14 to %word
	%r20 = icmp eq %word %r22, %r21
	%r19 = inttoptr i1 %r20 to %ptr
	%r24 = ptrtoint %ptr %r19 to %word
	%r23 = icmp ne %word %r24, 0
	br i1 %r23, label %L1162, label %L1163
L1163:
	%r25 = inttoptr %word 0 to %ptr
	store %ptr %r25, %ptr* %t4
	store %ptr %r25, %ptr* %t5
	%r26 = inttoptr %word 0 to %ptr
	%r30 = ptrtoint %ptr %r26 to %word
	%r29 = ptrtoint %ptr %r25 to %word
	%r28 = icmp eq %word %r30, %r29
	%r27 = inttoptr i1 %r28 to %ptr
	%r32 = ptrtoint %ptr %r27 to %word
	%r31 = icmp ne %word %r32, 0
	br i1 %r31, label %L1162, label %L1164
L1164:
	br label %L1162
L1162:
	%r33 = load %ptr, %ptr* %t5
	%r34 = load %ptr, %ptr* %t4
	store %ptr %r34, %ptr* %t3
	br label %L1161
L1160:
	%r35 = load %ptr, %ptr* %t1
	%r36 = call %ptr @"k/car"(%ptr %r35)
	store %ptr %r36, %ptr* %t4
	%r37 = inttoptr %word 0 to %ptr
	store %ptr %r37, %ptr* %t5
	%r38 = load %ptr, %ptr* %t4
	%r39 = call %ptr @"get/type"(%ptr %r38)
	%r40 = inttoptr %word 17 to %ptr
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = ptrtoint %ptr %r39 to %word
	%r42 = icmp eq %word %r44, %r43
	%r41 = inttoptr i1 %r42 to %ptr
	store %ptr %r41, %ptr* %t5
	%r45 = inttoptr %word 0 to %ptr
	%r49 = ptrtoint %ptr %r45 to %word
	%r48 = ptrtoint %ptr %r41 to %word
	%r47 = icmp eq %word %r49, %r48
	%r46 = inttoptr i1 %r47 to %ptr
	%r51 = ptrtoint %ptr %r46 to %word
	%r50 = icmp ne %word %r51, 0
	br i1 %r50, label %L1166, label %L1165
L1166:
	%r52 = getelementptr [28 x i8], [28 x i8]* @str1167, %word 0, %word 0
	%r54 = load %ptr, %ptr* %t4
	%r55 = call %ptr @fatal1(%ptr %r52, %ptr %r54)
	store %ptr %r55, %ptr* %t5
	%r56 = inttoptr %word 0 to %ptr
	%r60 = ptrtoint %ptr %r56 to %word
	%r59 = ptrtoint %ptr %r55 to %word
	%r58 = icmp eq %word %r60, %r59
	%r57 = inttoptr i1 %r58 to %ptr
	%r62 = ptrtoint %ptr %r57 to %word
	%r61 = icmp ne %word %r62, 0
	br i1 %r61, label %L1168, label %L1165
L1168:
	br label %L1165
L1165:
	%r63 = load %ptr, %ptr* %t5
	%r64 = load %ptr, %ptr* %t4
	store %ptr %r64, %ptr* %t5
	%r65 = inttoptr %word 0 to %ptr
	%r66 = inttoptr %word 1 to %ptr
	%r67 = load %ptr, %ptr* %t5
	%r71 = bitcast %ptr %r67 to [0 x %ptr]*
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = getelementptr [0 x %ptr], [0 x %ptr]* %r71, %word 0, %word %r70
	%r68 = load %ptr, %ptr* %r69
	store %ptr %r68, %ptr* %t5
	%r72 = load %ptr, %ptr* %t5
	%r73 = getelementptr [2 x i8], [2 x i8]* @str1169, %word 0, %word 0
	%r75 = call %ptr @fopen(%ptr %r72, %ptr %r73)
	store %ptr %r75, %ptr* %t6
	%r76 = load %ptr, %ptr* %t6
	%r78 = ptrtoint %ptr %r76 to %word
	%r77 = icmp ne %word %r78, 0
	br i1 %r77, label %L1170, label %L1171
L1170:
	%r79 = inttoptr %word 0 to %ptr
	%r80 = inttoptr %word 0 to %ptr
	%r81 = call %ptr @"new-<pair>"(%ptr %r79, %ptr %r80)
	store %ptr %r81, %ptr* %t8
	%r82 = load %ptr, %ptr* %t8
	store %ptr %r82, %ptr* %t9
	%r83 = inttoptr %word 0 to %ptr
	store %ptr %r83, %ptr* %t10
	%r85 = getelementptr %ptr, %ptr* %t8, %word 0
	%r84 = bitcast %ptr* %r85 to %ptr
	%r86 = call %ptr @"gc/push-root"(%ptr %r84)
	%r88 = getelementptr %ptr, %ptr* %t10, %word 0
	%r87 = bitcast %ptr* %r88 to %ptr
	%r89 = call %ptr @"gc/push-root"(%ptr %r87)
	br label %L1174
L1173:
	%r90 = load %ptr, %ptr* %t10
	%r91 = inttoptr %word 0 to %ptr
	%r92 = call %ptr @"new-<pair>"(%ptr %r90, %ptr %r91)
	%r93 = inttoptr %word 1 to %ptr
	%r94 = load %ptr, %ptr* %t9
	%r98 = bitcast %ptr %r94 to [0 x %ptr]*
	%r97 = ptrtoint %ptr %r93 to %word
	%r96 = getelementptr [0 x %ptr], [0 x %ptr]* %r98, %word 0, %word %r97
	store %ptr %r92, %ptr* %r96
	%r95 = bitcast %ptr %r92 to %ptr
	store %ptr %r95, %ptr* %t9
	br label %L1174
L1174:
	%r99 = load %ptr, %ptr* %t6
	%r100 = call %ptr @"k/read"(%ptr %r99)
	store %ptr %r100, %ptr* %t10
	%r101 = load %ptr, %ptr* @"k/+done+"
	%r105 = ptrtoint %ptr %r101 to %word
	%r104 = ptrtoint %ptr %r100 to %word
	%r103 = icmp ne %word %r105, %r104
	%r102 = inttoptr i1 %r103 to %ptr
	%r107 = ptrtoint %ptr %r102 to %word
	%r106 = icmp ne %word %r107, 0
	br i1 %r106, label %L1173, label %L1175
L1175:
	store %ptr %r102, %ptr* %t11
	%r109 = getelementptr %ptr, %ptr* %t10, %word 0
	%r108 = bitcast %ptr* %r109 to %ptr
	%r110 = call %ptr @"gc/pop-root"(%ptr %r108)
	%r112 = getelementptr %ptr, %ptr* %t8, %word 0
	%r111 = bitcast %ptr* %r112 to %ptr
	%r113 = call %ptr @"gc/pop-root"(%ptr %r111)
	%r114 = load %ptr, %ptr* %t11
	%r115 = load %ptr, %ptr* %t6
	%r116 = call i32 @fclose(%ptr %r115)
	%r117 = inttoptr %word %r116 to %ptr
	%r118 = inttoptr %word 1 to %ptr
	%r119 = load %ptr, %ptr* %t8
	%r123 = bitcast %ptr %r119 to [0 x %ptr]*
	%r122 = ptrtoint %ptr %r118 to %word
	%r121 = getelementptr [0 x %ptr], [0 x %ptr]* %r123, %word 0, %word %r122
	%r120 = load %ptr, %ptr* %r121
	store %ptr %r120, %ptr* %t7
	br label %L1172
L1171:
	%r124 = inttoptr %word 0 to %ptr
	store %ptr %r124, %ptr* %t7
	br label %L1172
L1172:
	%r125 = load %ptr, %ptr* %t7
	store %ptr %r125, %ptr* %t3
	br label %L1161
L1161:
	%r126 = load %ptr, %ptr* %t3
	ret %ptr %r126
}
define %ptr @"subr/current-module"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* @"*module*"
	ret %ptr %r2
}
@str1176 = private unnamed_addr constant [2 x i8] c"t\00"
@str1177 = private unnamed_addr constant [2 x i8] c".\00"
@str1178 = private unnamed_addr constant [7 x i8] c"define\00"
@str1179 = private unnamed_addr constant [4 x i8] c"set\00"
@str1180 = private unnamed_addr constant [6 x i8] c"quote\00"
@str1181 = private unnamed_addr constant [11 x i8] c"quasiquote\00"
@str1182 = private unnamed_addr constant [8 x i8] c"unquote\00"
@str1183 = private unnamed_addr constant [17 x i8] c"unquote-splicing\00"
@str1184 = private unnamed_addr constant [12 x i8] c"*expanders*\00"
@str1185 = private unnamed_addr constant [11 x i8] c"*encoders*\00"
@str1186 = private unnamed_addr constant [13 x i8] c"*evaluators*\00"
@str1187 = private unnamed_addr constant [14 x i8] c"*applicators*\00"
@str1188 = private unnamed_addr constant [8 x i8] c"*input*\00"
@str1189 = private unnamed_addr constant [6 x i8] c"quote\00"
@str1190 = private unnamed_addr constant [7 x i8] c"lambda\00"
@str1191 = private unnamed_addr constant [4 x i8] c"let\00"
@str1192 = private unnamed_addr constant [7 x i8] c"define\00"
@str1193 = private unnamed_addr constant [4 x i8] c"set\00"
@str1202 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str1203 = private unnamed_addr constant [39 x i8] c"capture-well-known-vm-values: assert 2\00"
@str1204 = private unnamed_addr constant [2 x i8] c"\0A\00"
define %ptr @capture-well-known-vm-values() {
	%t1 = alloca %ptr
	%t2 = alloca %ptr
	%t3 = alloca %ptr
	%r1 = inttoptr %word 0 to %ptr
	%r2 = getelementptr [2 x i8], [2 x i8]* @str1176, %word 0, %word 0
	%r4 = call %ptr @intern(%ptr %r2)
	store %ptr %r4, %ptr* @"symbol/t"
	%r5 = getelementptr [2 x i8], [2 x i8]* @str1177, %word 0, %word 0
	%r7 = call %ptr @intern(%ptr %r5)
	store %ptr %r7, %ptr* @"symbol/dot"
	%r8 = getelementptr [7 x i8], [7 x i8]* @str1178, %word 0, %word 0
	%r10 = call %ptr @intern(%ptr %r8)
	store %ptr %r10, %ptr* @"symbol/define"
	%r11 = getelementptr [4 x i8], [4 x i8]* @str1179, %word 0, %word 0
	%r13 = call %ptr @intern(%ptr %r11)
	store %ptr %r13, %ptr* @"symbol/set"
	%r14 = getelementptr [6 x i8], [6 x i8]* @str1180, %word 0, %word 0
	%r16 = call %ptr @intern(%ptr %r14)
	store %ptr %r16, %ptr* @"symbol/quote"
	%r17 = getelementptr [11 x i8], [11 x i8]* @str1181, %word 0, %word 0
	%r19 = call %ptr @intern(%ptr %r17)
	store %ptr %r19, %ptr* @"symbol/quasiquote"
	%r20 = getelementptr [8 x i8], [8 x i8]* @str1182, %word 0, %word 0
	%r22 = call %ptr @intern(%ptr %r20)
	store %ptr %r22, %ptr* @"symbol/unquote"
	%r23 = getelementptr [17 x i8], [17 x i8]* @str1183, %word 0, %word 0
	%r25 = call %ptr @intern(%ptr %r23)
	store %ptr %r25, %ptr* @"symbol/unquote_splicing"
	%r26 = load %ptr, %ptr* @"*module*"
	store %ptr %r26, %ptr* %t1
	%r27 = inttoptr %word 0 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t1
	%r33 = bitcast %ptr %r29 to [0 x %ptr]*
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = getelementptr [0 x %ptr], [0 x %ptr]* %r33, %word 0, %word %r32
	%r30 = load %ptr, %ptr* %r31
	store %ptr %r30, %ptr* %t1
	%r34 = inttoptr %word 0 to %ptr
	%r35 = inttoptr %word 1 to %ptr
	%r36 = load %ptr, %ptr* %t1
	%r40 = bitcast %ptr %r36 to [0 x %ptr]*
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = getelementptr [0 x %ptr], [0 x %ptr]* %r40, %word 0, %word %r39
	%r37 = load %ptr, %ptr* %r38
	store %ptr %r37, %ptr* %t1
	%r41 = load %ptr, %ptr* %t1
	%r42 = getelementptr [12 x i8], [12 x i8]* @str1184, %word 0, %word 0
	%r44 = call %ptr @intern(%ptr %r42)
	%r45 = call %ptr @"k/env/lookup-variable-or-die"(%ptr %r41, %ptr %r44)
	store %ptr %r45, %ptr* @"var/*expanders*"
	%r46 = load %ptr, %ptr* %t1
	%r47 = getelementptr [11 x i8], [11 x i8]* @str1185, %word 0, %word 0
	%r49 = call %ptr @intern(%ptr %r47)
	%r50 = call %ptr @"k/env/lookup-variable-or-die"(%ptr %r46, %ptr %r49)
	store %ptr %r50, %ptr* @"var/*encoders*"
	%r51 = load %ptr, %ptr* %t1
	%r52 = getelementptr [13 x i8], [13 x i8]* @str1186, %word 0, %word 0
	%r54 = call %ptr @intern(%ptr %r52)
	%r55 = call %ptr @"k/env/lookup-variable-or-die"(%ptr %r51, %ptr %r54)
	store %ptr %r55, %ptr* @"var/*evaluators*"
	%r56 = load %ptr, %ptr* %t1
	%r57 = getelementptr [14 x i8], [14 x i8]* @str1187, %word 0, %word 0
	%r59 = call %ptr @intern(%ptr %r57)
	%r60 = call %ptr @"k/env/lookup-variable-or-die"(%ptr %r56, %ptr %r59)
	store %ptr %r60, %ptr* @"var/*applicators*"
	%r61 = load %ptr, %ptr* %t1
	%r62 = getelementptr [8 x i8], [8 x i8]* @str1188, %word 0, %word 0
	%r64 = call %ptr @intern(%ptr %r62)
	%r65 = call %ptr @"k/env/lookup-variable-or-die"(%ptr %r61, %ptr %r64)
	store %ptr %r65, %ptr* @"var/*input*"
	%r66 = load %ptr, %ptr* %t1
	%r67 = getelementptr [6 x i8], [6 x i8]* @str1189, %word 0, %word 0
	%r69 = call %ptr @intern(%ptr %r67)
	%r70 = call %ptr @"k/env/variable-value"(%ptr %r66, %ptr %r69)
	store %ptr %r70, %ptr* @"fixed-subr/quote"
	%r71 = load %ptr, %ptr* %t1
	%r72 = getelementptr [7 x i8], [7 x i8]* @str1190, %word 0, %word 0
	%r74 = call %ptr @intern(%ptr %r72)
	%r75 = call %ptr @"k/env/variable-value"(%ptr %r71, %ptr %r74)
	store %ptr %r75, %ptr* @"fixed-subr/lambda"
	%r76 = load %ptr, %ptr* %t1
	%r77 = getelementptr [4 x i8], [4 x i8]* @str1191, %word 0, %word 0
	%r79 = call %ptr @intern(%ptr %r77)
	%r80 = call %ptr @"k/env/variable-value"(%ptr %r76, %ptr %r79)
	store %ptr %r80, %ptr* @"fixed-subr/let"
	%r81 = load %ptr, %ptr* %t1
	%r82 = getelementptr [7 x i8], [7 x i8]* @str1192, %word 0, %word 0
	%r84 = call %ptr @intern(%ptr %r82)
	%r85 = call %ptr @"k/env/variable-value"(%ptr %r81, %ptr %r84)
	store %ptr %r85, %ptr* @"fixed-subr/define"
	%r86 = load %ptr, %ptr* %t1
	%r87 = getelementptr [4 x i8], [4 x i8]* @str1193, %word 0, %word 0
	%r89 = call %ptr @intern(%ptr %r87)
	%r90 = call %ptr @"k/env/variable-value"(%ptr %r86, %ptr %r89)
	store %ptr %r90, %ptr* @"fixed-subr/set"
	%r91 = inttoptr %word 0 to %ptr
	store %ptr %r91, %ptr* %t2
	%r92 = inttoptr %word 1 to %ptr
	store %ptr %r92, %ptr* %t3
	%r93 = load %ptr, %ptr* @"fixed-subr/quote"
	%r94 = call %ptr @"get/type"(%ptr %r93)
	%r95 = inttoptr %word 10 to %ptr
	%r99 = ptrtoint %ptr %r95 to %word
	%r98 = ptrtoint %ptr %r94 to %word
	%r97 = icmp eq %word %r99, %r98
	%r96 = inttoptr i1 %r97 to %ptr
	store %ptr %r96, %ptr* %t3
	%r100 = inttoptr %word 0 to %ptr
	%r104 = ptrtoint %ptr %r100 to %word
	%r103 = ptrtoint %ptr %r96 to %word
	%r102 = icmp eq %word %r104, %r103
	%r101 = inttoptr i1 %r102 to %ptr
	%r106 = ptrtoint %ptr %r101 to %word
	%r105 = icmp ne %word %r106, 0
	br i1 %r105, label %L1195, label %L1196
L1196:
	%r107 = load %ptr, %ptr* @"fixed-subr/lambda"
	%r108 = call %ptr @"get/type"(%ptr %r107)
	%r109 = inttoptr %word 10 to %ptr
	%r113 = ptrtoint %ptr %r109 to %word
	%r112 = ptrtoint %ptr %r108 to %word
	%r111 = icmp eq %word %r113, %r112
	%r110 = inttoptr i1 %r111 to %ptr
	store %ptr %r110, %ptr* %t3
	%r114 = inttoptr %word 0 to %ptr
	%r118 = ptrtoint %ptr %r114 to %word
	%r117 = ptrtoint %ptr %r110 to %word
	%r116 = icmp eq %word %r118, %r117
	%r115 = inttoptr i1 %r116 to %ptr
	%r120 = ptrtoint %ptr %r115 to %word
	%r119 = icmp ne %word %r120, 0
	br i1 %r119, label %L1195, label %L1197
L1197:
	%r121 = load %ptr, %ptr* @"fixed-subr/let"
	%r122 = call %ptr @"get/type"(%ptr %r121)
	%r123 = inttoptr %word 10 to %ptr
	%r127 = ptrtoint %ptr %r123 to %word
	%r126 = ptrtoint %ptr %r122 to %word
	%r125 = icmp eq %word %r127, %r126
	%r124 = inttoptr i1 %r125 to %ptr
	store %ptr %r124, %ptr* %t3
	%r128 = inttoptr %word 0 to %ptr
	%r132 = ptrtoint %ptr %r128 to %word
	%r131 = ptrtoint %ptr %r124 to %word
	%r130 = icmp eq %word %r132, %r131
	%r129 = inttoptr i1 %r130 to %ptr
	%r134 = ptrtoint %ptr %r129 to %word
	%r133 = icmp ne %word %r134, 0
	br i1 %r133, label %L1195, label %L1198
L1198:
	%r135 = load %ptr, %ptr* @"fixed-subr/define"
	%r136 = call %ptr @"get/type"(%ptr %r135)
	%r137 = inttoptr %word 10 to %ptr
	%r141 = ptrtoint %ptr %r137 to %word
	%r140 = ptrtoint %ptr %r136 to %word
	%r139 = icmp eq %word %r141, %r140
	%r138 = inttoptr i1 %r139 to %ptr
	store %ptr %r138, %ptr* %t3
	%r142 = inttoptr %word 0 to %ptr
	%r146 = ptrtoint %ptr %r142 to %word
	%r145 = ptrtoint %ptr %r138 to %word
	%r144 = icmp eq %word %r146, %r145
	%r143 = inttoptr i1 %r144 to %ptr
	%r148 = ptrtoint %ptr %r143 to %word
	%r147 = icmp ne %word %r148, 0
	br i1 %r147, label %L1195, label %L1199
L1199:
	%r149 = load %ptr, %ptr* @"fixed-subr/set"
	%r150 = call %ptr @"get/type"(%ptr %r149)
	%r151 = inttoptr %word 10 to %ptr
	%r155 = ptrtoint %ptr %r151 to %word
	%r154 = ptrtoint %ptr %r150 to %word
	%r153 = icmp eq %word %r155, %r154
	%r152 = inttoptr i1 %r153 to %ptr
	store %ptr %r152, %ptr* %t3
	%r156 = inttoptr %word 0 to %ptr
	%r160 = ptrtoint %ptr %r156 to %word
	%r159 = ptrtoint %ptr %r152 to %word
	%r158 = icmp eq %word %r160, %r159
	%r157 = inttoptr i1 %r158 to %ptr
	%r162 = ptrtoint %ptr %r157 to %word
	%r161 = icmp ne %word %r162, 0
	br i1 %r161, label %L1195, label %L1200
L1200:
	br label %L1195
L1195:
	%r163 = load %ptr, %ptr* %t3
	store %ptr %r163, %ptr* %t2
	%r164 = inttoptr %word 0 to %ptr
	%r168 = ptrtoint %ptr %r164 to %word
	%r167 = ptrtoint %ptr %r163 to %word
	%r166 = icmp eq %word %r168, %r167
	%r165 = inttoptr i1 %r166 to %ptr
	%r170 = ptrtoint %ptr %r165 to %word
	%r169 = icmp ne %word %r170, 0
	br i1 %r169, label %L1201, label %L1194
L1201:
	%r171 = getelementptr [9 x i8], [9 x i8]* @str1202, %word 0, %word 0
	%r173 = call i32 (%ptr, ...) @printf(%ptr %r171)
	%r174 = inttoptr %word %r173 to %ptr
	%r175 = getelementptr [39 x i8], [39 x i8]* @str1203, %word 0, %word 0
	%r177 = call i32 (%ptr, ...) @printf(%ptr %r175)
	%r178 = inttoptr %word %r177 to %ptr
	%r179 = getelementptr [2 x i8], [2 x i8]* @str1204, %word 0, %word 0
	%r181 = call i32 (%ptr, ...) @printf(%ptr %r179)
	%r182 = inttoptr %word %r181 to %ptr
	%r183 = call %ptr @die()
	store %ptr %r183, %ptr* %t2
	%r184 = inttoptr %word 0 to %ptr
	%r188 = ptrtoint %ptr %r184 to %word
	%r187 = ptrtoint %ptr %r183 to %word
	%r186 = icmp eq %word %r188, %r187
	%r185 = inttoptr i1 %r186 to %ptr
	%r190 = ptrtoint %ptr %r185 to %word
	%r189 = icmp ne %word %r190, 0
	br i1 %r189, label %L1205, label %L1194
L1205:
	br label %L1194
L1194:
	%r191 = load %ptr, %ptr* %t2
	%r192 = inttoptr %word 0 to %ptr
	ret %ptr %r192
}
@str1206 = private unnamed_addr constant [8 x i8] c"*input*\00"
@str1207 = private unnamed_addr constant [25 x i8] c"*command-line-arguments*\00"
@str1208 = private unnamed_addr constant [12 x i8] c"*verbosity*\00"
@str1209 = private unnamed_addr constant [12 x i8] c"*optimised*\00"
@str1210 = private unnamed_addr constant [7 x i8] c"+done+\00"
@str1211 = private unnamed_addr constant [15 x i8] c"bootstrapping?\00"
@str1212 = private unnamed_addr constant [10 x i8] c"evolving?\00"
@str1213 = private unnamed_addr constant [12 x i8] c"*expanders*\00"
@str1214 = private unnamed_addr constant [11 x i8] c"*encoders*\00"
@str1215 = private unnamed_addr constant [13 x i8] c"*evaluators*\00"
@str1216 = private unnamed_addr constant [14 x i8] c"*applicators*\00"
@str1217 = private unnamed_addr constant [7 x i8] c"define\00"
@str1218 = private unnamed_addr constant [9 x i8] c"defined?\00"
@str1219 = private unnamed_addr constant [7 x i8] c"lambda\00"
@str1220 = private unnamed_addr constant [4 x i8] c"let\00"
@str1221 = private unnamed_addr constant [4 x i8] c"set\00"
@str1222 = private unnamed_addr constant [6 x i8] c"while\00"
@str1223 = private unnamed_addr constant [3 x i8] c"if\00"
@str1224 = private unnamed_addr constant [3 x i8] c"or\00"
@str1225 = private unnamed_addr constant [4 x i8] c"and\00"
@str1226 = private unnamed_addr constant [6 x i8] c"quote\00"
@str1227 = private unnamed_addr constant [4 x i8] c"not\00"
@str1228 = private unnamed_addr constant [6 x i8] c"fixed\00"
@str1229 = private unnamed_addr constant [9 x i8] c"variable\00"
@str1230 = private unnamed_addr constant [12 x i8] c"environment\00"
@str1231 = private unnamed_addr constant [19 x i8] c"environment-define\00"
@str1232 = private unnamed_addr constant [2 x i8] c"-\00"
@str1233 = private unnamed_addr constant [2 x i8] c"&\00"
@str1234 = private unnamed_addr constant [2 x i8] c"|\00"
@str1235 = private unnamed_addr constant [2 x i8] c"^\00"
@str1236 = private unnamed_addr constant [2 x i8] c"+\00"
@str1237 = private unnamed_addr constant [2 x i8] c"*\00"
@str1238 = private unnamed_addr constant [2 x i8] c"/\00"
@str1239 = private unnamed_addr constant [3 x i8] c"<<\00"
@str1240 = private unnamed_addr constant [3 x i8] c">>\00"
@str1241 = private unnamed_addr constant [2 x i8] c"<\00"
@str1242 = private unnamed_addr constant [3 x i8] c"<=\00"
@str1243 = private unnamed_addr constant [3 x i8] c">=\00"
@str1244 = private unnamed_addr constant [2 x i8] c">\00"
@str1245 = private unnamed_addr constant [2 x i8] c"=\00"
@str1246 = private unnamed_addr constant [3 x i8] c"!=\00"
@str1247 = private unnamed_addr constant [6 x i8] c"abort\00"
@str1248 = private unnamed_addr constant [5 x i8] c"exit\00"
@str1249 = private unnamed_addr constant [11 x i8] c"libc/fopen\00"
@str1250 = private unnamed_addr constant [12 x i8] c"libc/fclose\00"
@str1251 = private unnamed_addr constant [11 x i8] c"libc/fgetc\00"
@str1252 = private unnamed_addr constant [11 x i8] c"libc/fputc\00"
@str1253 = private unnamed_addr constant [12 x i8] c"libc/format\00"
@str1254 = private unnamed_addr constant [12 x i8] c"repl-stream\00"
@str1255 = private unnamed_addr constant [5 x i8] c"dump\00"
@str1256 = private unnamed_addr constant [6 x i8] c"print\00"
@str1257 = private unnamed_addr constant [5 x i8] c"warn\00"
@str1258 = private unnamed_addr constant [6 x i8] c"apply\00"
@str1259 = private unnamed_addr constant [5 x i8] c"eval\00"
@str1260 = private unnamed_addr constant [7 x i8] c"encode\00"
@str1261 = private unnamed_addr constant [7 x i8] c"expand\00"
@str1262 = private unnamed_addr constant [5 x i8] c"cons\00"
@str1263 = private unnamed_addr constant [7 x i8] c"string\00"
@str1264 = private unnamed_addr constant [6 x i8] c"array\00"
@str1265 = private unnamed_addr constant [5 x i8] c"form\00"
@str1266 = private unnamed_addr constant [9 x i8] c"allocate\00"
@str1267 = private unnamed_addr constant [8 x i8] c"type-of\00"
@str1268 = private unnamed_addr constant [8 x i8] c"string?\00"
@str1269 = private unnamed_addr constant [8 x i8] c"symbol?\00"
@str1270 = private unnamed_addr constant [6 x i8] c"pair?\00"
@str1271 = private unnamed_addr constant [7 x i8] c"array?\00"
@str1272 = private unnamed_addr constant [4 x i8] c"car\00"
@str1273 = private unnamed_addr constant [4 x i8] c"cdr\00"
@str1274 = private unnamed_addr constant [8 x i8] c"set-car\00"
@str1275 = private unnamed_addr constant [8 x i8] c"set-cdr\00"
@str1276 = private unnamed_addr constant [7 x i8] c"oop-at\00"
@str1277 = private unnamed_addr constant [11 x i8] c"set-oop-at\00"
@str1278 = private unnamed_addr constant [13 x i8] c"array-length\00"
@str1279 = private unnamed_addr constant [9 x i8] c"array-at\00"
@str1280 = private unnamed_addr constant [13 x i8] c"set-array-at\00"
@str1281 = private unnamed_addr constant [13 x i8] c"array-insert\00"
@str1282 = private unnamed_addr constant [14 x i8] c"string-length\00"
@str1283 = private unnamed_addr constant [10 x i8] c"string-at\00"
@str1284 = private unnamed_addr constant [14 x i8] c"set-string-at\00"
@str1285 = private unnamed_addr constant [15 x i8] c"string->symbol\00"
@str1286 = private unnamed_addr constant [15 x i8] c"symbol->string\00"
@str1287 = private unnamed_addr constant [13 x i8] c"long->string\00"
@str1288 = private unnamed_addr constant [5 x i8] c"read\00"
@str1289 = private unnamed_addr constant [15 x i8] c"current-module\00"
@str1290 = private unnamed_addr constant [19 x i8] c"set-current-module\00"
@str1291 = private unnamed_addr constant [14 x i8] c"create-module\00"
@str1292 = private unnamed_addr constant [15 x i8] c"eval-in-module\00"
define %ptr @populate-module-with-primitives(%ptr %module) {
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %module, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = load %ptr, %ptr* %t1
	store %ptr %r3, %ptr* %t2
	%r4 = inttoptr %word 0 to %ptr
	%r5 = inttoptr %word 1 to %ptr
	%r6 = load %ptr, %ptr* %t2
	%r10 = bitcast %ptr %r6 to [0 x %ptr]*
	%r9 = ptrtoint %ptr %r5 to %word
	%r8 = getelementptr [0 x %ptr], [0 x %ptr]* %r10, %word 0, %word %r9
	%r7 = load %ptr, %ptr* %r8
	store %ptr %r7, %ptr* %t2
	%r11 = inttoptr %word 0 to %ptr
	%r12 = inttoptr %word 1 to %ptr
	%r13 = load %ptr, %ptr* %t2
	%r17 = bitcast %ptr %r13 to [0 x %ptr]*
	%r16 = ptrtoint %ptr %r12 to %word
	%r15 = getelementptr [0 x %ptr], [0 x %ptr]* %r17, %word 0, %word %r16
	%r14 = load %ptr, %ptr* %r15
	store %ptr %r14, %ptr* %t2
	%r18 = inttoptr %word 0 to %ptr
	store %ptr %r18, %ptr* %t3
	%r20 = getelementptr %ptr, %ptr* %t3, %word 0
	%r19 = bitcast %ptr* %r20 to %ptr
	%r21 = call %ptr @"gc/push-root"(%ptr %r19)
	%r22 = load %ptr, %ptr* %t2
	%r23 = getelementptr [8 x i8], [8 x i8]* @str1206, %word 0, %word 0
	%r25 = load %ptr, %ptr* %t1
	%r26 = call %ptr @"intern*"(%ptr %r23, %ptr %r25)
	%r27 = inttoptr %word 0 to %ptr
	%r28 = call %ptr @"k/env/define"(%ptr %r22, %ptr %r26, %ptr %r27)
	%r29 = load %ptr, %ptr* %t2
	%r30 = getelementptr [25 x i8], [25 x i8]* @str1207, %word 0, %word 0
	%r32 = load %ptr, %ptr* %t1
	%r33 = call %ptr @"intern*"(%ptr %r30, %ptr %r32)
	%r34 = inttoptr %word 0 to %ptr
	%r35 = call %ptr @"k/env/define"(%ptr %r29, %ptr %r33, %ptr %r34)
	%r36 = inttoptr %word 1 to %ptr
	%r37 = inttoptr %word 1 to %ptr
	%r38 = inttoptr %word 0 to %ptr
	%r42 = ptrtoint %ptr %r38 to %word
	%r41 = ptrtoint %ptr %r37 to %word
	%r40 = shl %word %r42, %r41
	%r39 = inttoptr %word %r40 to %ptr
	%r46 = ptrtoint %ptr %r39 to %word
	%r45 = ptrtoint %ptr %r36 to %word
	%r44 = add %word %r46, %r45
	%r43 = inttoptr %word %r44 to %ptr
	store %ptr %r43, %ptr* %t3
	%r47 = load %ptr, %ptr* %t2
	%r48 = getelementptr [12 x i8], [12 x i8]* @str1208, %word 0, %word 0
	%r50 = load %ptr, %ptr* %t1
	%r51 = call %ptr @"intern*"(%ptr %r48, %ptr %r50)
	%r52 = load %ptr, %ptr* %t3
	%r53 = call %ptr @"k/env/define"(%ptr %r47, %ptr %r51, %ptr %r52)
	%r54 = inttoptr %word 1 to %ptr
	%r55 = inttoptr %word 1 to %ptr
	%r56 = inttoptr %word 0 to %ptr
	%r60 = ptrtoint %ptr %r56 to %word
	%r59 = ptrtoint %ptr %r55 to %word
	%r58 = shl %word %r60, %r59
	%r57 = inttoptr %word %r58 to %ptr
	%r64 = ptrtoint %ptr %r57 to %word
	%r63 = ptrtoint %ptr %r54 to %word
	%r62 = add %word %r64, %r63
	%r61 = inttoptr %word %r62 to %ptr
	store %ptr %r61, %ptr* %t3
	%r65 = load %ptr, %ptr* %t2
	%r66 = getelementptr [12 x i8], [12 x i8]* @str1209, %word 0, %word 0
	%r68 = load %ptr, %ptr* %t1
	%r69 = call %ptr @"intern*"(%ptr %r66, %ptr %r68)
	%r70 = load %ptr, %ptr* %t3
	%r71 = call %ptr @"k/env/define"(%ptr %r65, %ptr %r69, %ptr %r70)
	%r72 = load %ptr, %ptr* %t2
	%r73 = getelementptr [7 x i8], [7 x i8]* @str1210, %word 0, %word 0
	%r75 = load %ptr, %ptr* %t1
	%r76 = call %ptr @"intern*"(%ptr %r73, %ptr %r75)
	%r77 = load %ptr, %ptr* @"k/+done+"
	%r78 = call %ptr @"k/env/define"(%ptr %r72, %ptr %r76, %ptr %r77)
	%r79 = load %ptr, %ptr* %t2
	%r80 = getelementptr [15 x i8], [15 x i8]* @str1211, %word 0, %word 0
	%r82 = load %ptr, %ptr* %t1
	%r83 = call %ptr @"intern*"(%ptr %r80, %ptr %r82)
	%r84 = inttoptr %word 0 to %ptr
	%r85 = call %ptr @"k/env/define"(%ptr %r79, %ptr %r83, %ptr %r84)
	%r86 = load %ptr, %ptr* %t2
	%r87 = getelementptr [10 x i8], [10 x i8]* @str1212, %word 0, %word 0
	%r89 = load %ptr, %ptr* %t1
	%r90 = call %ptr @"intern*"(%ptr %r87, %ptr %r89)
	%r91 = inttoptr %word 0 to %ptr
	%r92 = call %ptr @"k/env/define"(%ptr %r86, %ptr %r90, %ptr %r91)
	%r93 = inttoptr %word 0 to %ptr
	%r94 = call %ptr @"new-<array>"(%ptr %r93)
	store %ptr %r94, %ptr* %t3
	%r95 = load %ptr, %ptr* %t2
	%r96 = getelementptr [12 x i8], [12 x i8]* @str1213, %word 0, %word 0
	%r98 = load %ptr, %ptr* %t1
	%r99 = call %ptr @"intern*"(%ptr %r96, %ptr %r98)
	%r100 = load %ptr, %ptr* %t3
	%r101 = call %ptr @"k/env/define"(%ptr %r95, %ptr %r99, %ptr %r100)
	%r102 = inttoptr %word 0 to %ptr
	%r103 = call %ptr @"new-<array>"(%ptr %r102)
	store %ptr %r103, %ptr* %t3
	%r104 = load %ptr, %ptr* %t2
	%r105 = getelementptr [11 x i8], [11 x i8]* @str1214, %word 0, %word 0
	%r107 = load %ptr, %ptr* %t1
	%r108 = call %ptr @"intern*"(%ptr %r105, %ptr %r107)
	%r109 = load %ptr, %ptr* %t3
	%r110 = call %ptr @"k/env/define"(%ptr %r104, %ptr %r108, %ptr %r109)
	%r111 = inttoptr %word 0 to %ptr
	%r112 = call %ptr @"new-<array>"(%ptr %r111)
	store %ptr %r112, %ptr* %t3
	%r113 = load %ptr, %ptr* %t2
	%r114 = getelementptr [13 x i8], [13 x i8]* @str1215, %word 0, %word 0
	%r116 = load %ptr, %ptr* %t1
	%r117 = call %ptr @"intern*"(%ptr %r114, %ptr %r116)
	%r118 = load %ptr, %ptr* %t3
	%r119 = call %ptr @"k/env/define"(%ptr %r113, %ptr %r117, %ptr %r118)
	%r120 = inttoptr %word 0 to %ptr
	%r121 = call %ptr @"new-<array>"(%ptr %r120)
	store %ptr %r121, %ptr* %t3
	%r122 = load %ptr, %ptr* %t2
	%r123 = getelementptr [14 x i8], [14 x i8]* @str1216, %word 0, %word 0
	%r125 = load %ptr, %ptr* %t1
	%r126 = call %ptr @"intern*"(%ptr %r123, %ptr %r125)
	%r127 = load %ptr, %ptr* %t3
	%r128 = call %ptr @"k/env/define"(%ptr %r122, %ptr %r126, %ptr %r127)
	store %ptr %r128, %ptr* %t4
	%r130 = getelementptr %ptr, %ptr* %t3, %word 0
	%r129 = bitcast %ptr* %r130 to %ptr
	%r131 = call %ptr @"gc/pop-root"(%ptr %r129)
	%r132 = load %ptr, %ptr* %t4
	%r133 = getelementptr [7 x i8], [7 x i8]* @str1217, %word 0, %word 0
	%r135 = bitcast %ptr (%ptr, %ptr)* @"subr/define" to %ptr
	%r136 = inttoptr %word 1 to %ptr
	%r137 = load %ptr, %ptr* %t1
	%r138 = call %ptr @"%instantiate-subr"(%ptr %r133, %ptr %r135, %ptr %r136, %ptr %r137)
	%r139 = getelementptr [9 x i8], [9 x i8]* @str1218, %word 0, %word 0
	%r141 = bitcast %ptr (%ptr, %ptr)* @"subr/defined?" to %ptr
	%r142 = inttoptr %word 0 to %ptr
	%r143 = load %ptr, %ptr* %t1
	%r144 = call %ptr @"%instantiate-subr"(%ptr %r139, %ptr %r141, %ptr %r142, %ptr %r143)
	%r145 = getelementptr [7 x i8], [7 x i8]* @str1219, %word 0, %word 0
	%r147 = bitcast %ptr (%ptr, %ptr)* @"subr/lambda" to %ptr
	%r148 = inttoptr %word 1 to %ptr
	%r149 = load %ptr, %ptr* %t1
	%r150 = call %ptr @"%instantiate-subr"(%ptr %r145, %ptr %r147, %ptr %r148, %ptr %r149)
	%r151 = getelementptr [4 x i8], [4 x i8]* @str1220, %word 0, %word 0
	%r153 = bitcast %ptr (%ptr, %ptr)* @"subr/let" to %ptr
	%r154 = inttoptr %word 1 to %ptr
	%r155 = load %ptr, %ptr* %t1
	%r156 = call %ptr @"%instantiate-subr"(%ptr %r151, %ptr %r153, %ptr %r154, %ptr %r155)
	%r157 = getelementptr [4 x i8], [4 x i8]* @str1221, %word 0, %word 0
	%r159 = bitcast %ptr (%ptr, %ptr)* @"subr/set" to %ptr
	%r160 = inttoptr %word 1 to %ptr
	%r161 = load %ptr, %ptr* %t1
	%r162 = call %ptr @"%instantiate-subr"(%ptr %r157, %ptr %r159, %ptr %r160, %ptr %r161)
	%r163 = getelementptr [6 x i8], [6 x i8]* @str1222, %word 0, %word 0
	%r165 = bitcast %ptr (%ptr, %ptr)* @"subr/while" to %ptr
	%r166 = inttoptr %word 1 to %ptr
	%r167 = load %ptr, %ptr* %t1
	%r168 = call %ptr @"%instantiate-subr"(%ptr %r163, %ptr %r165, %ptr %r166, %ptr %r167)
	%r169 = getelementptr [3 x i8], [3 x i8]* @str1223, %word 0, %word 0
	%r171 = bitcast %ptr (%ptr, %ptr)* @"subr/if" to %ptr
	%r172 = inttoptr %word 1 to %ptr
	%r173 = load %ptr, %ptr* %t1
	%r174 = call %ptr @"%instantiate-subr"(%ptr %r169, %ptr %r171, %ptr %r172, %ptr %r173)
	%r175 = getelementptr [3 x i8], [3 x i8]* @str1224, %word 0, %word 0
	%r177 = bitcast %ptr (%ptr, %ptr)* @"subr/or" to %ptr
	%r178 = inttoptr %word 1 to %ptr
	%r179 = load %ptr, %ptr* %t1
	%r180 = call %ptr @"%instantiate-subr"(%ptr %r175, %ptr %r177, %ptr %r178, %ptr %r179)
	%r181 = getelementptr [4 x i8], [4 x i8]* @str1225, %word 0, %word 0
	%r183 = bitcast %ptr (%ptr, %ptr)* @"subr/and" to %ptr
	%r184 = inttoptr %word 1 to %ptr
	%r185 = load %ptr, %ptr* %t1
	%r186 = call %ptr @"%instantiate-subr"(%ptr %r181, %ptr %r183, %ptr %r184, %ptr %r185)
	%r187 = getelementptr [6 x i8], [6 x i8]* @str1226, %word 0, %word 0
	%r189 = bitcast %ptr (%ptr, %ptr)* @"subr/quote" to %ptr
	%r190 = inttoptr %word 1 to %ptr
	%r191 = load %ptr, %ptr* %t1
	%r192 = call %ptr @"%instantiate-subr"(%ptr %r187, %ptr %r189, %ptr %r190, %ptr %r191)
	%r193 = getelementptr [4 x i8], [4 x i8]* @str1227, %word 0, %word 0
	%r195 = bitcast %ptr (%ptr, %ptr)* @"subr/not" to %ptr
	%r196 = inttoptr %word 0 to %ptr
	%r197 = load %ptr, %ptr* %t1
	%r198 = call %ptr @"%instantiate-subr"(%ptr %r193, %ptr %r195, %ptr %r196, %ptr %r197)
	%r199 = getelementptr [6 x i8], [6 x i8]* @str1228, %word 0, %word 0
	%r201 = bitcast %ptr (%ptr, %ptr)* @"subr/fixed" to %ptr
	%r202 = inttoptr %word 0 to %ptr
	%r203 = load %ptr, %ptr* %t1
	%r204 = call %ptr @"%instantiate-subr"(%ptr %r199, %ptr %r201, %ptr %r202, %ptr %r203)
	%r205 = getelementptr [9 x i8], [9 x i8]* @str1229, %word 0, %word 0
	%r207 = bitcast %ptr (%ptr, %ptr)* @"subr/variable" to %ptr
	%r208 = inttoptr %word 0 to %ptr
	%r209 = load %ptr, %ptr* %t1
	%r210 = call %ptr @"%instantiate-subr"(%ptr %r205, %ptr %r207, %ptr %r208, %ptr %r209)
	%r211 = getelementptr [12 x i8], [12 x i8]* @str1230, %word 0, %word 0
	%r213 = bitcast %ptr (%ptr, %ptr)* @"subr/environment" to %ptr
	%r214 = inttoptr %word 0 to %ptr
	%r215 = load %ptr, %ptr* %t1
	%r216 = call %ptr @"%instantiate-subr"(%ptr %r211, %ptr %r213, %ptr %r214, %ptr %r215)
	%r217 = getelementptr [19 x i8], [19 x i8]* @str1231, %word 0, %word 0
	%r219 = bitcast %ptr (%ptr, %ptr)* @"subr/environment-define" to %ptr
	%r220 = inttoptr %word 0 to %ptr
	%r221 = load %ptr, %ptr* %t1
	%r222 = call %ptr @"%instantiate-subr"(%ptr %r217, %ptr %r219, %ptr %r220, %ptr %r221)
	%r223 = getelementptr [2 x i8], [2 x i8]* @str1232, %word 0, %word 0
	%r225 = bitcast %ptr (%ptr, %ptr)* @"subr/-" to %ptr
	%r226 = inttoptr %word 0 to %ptr
	%r227 = load %ptr, %ptr* %t1
	%r228 = call %ptr @"%instantiate-subr"(%ptr %r223, %ptr %r225, %ptr %r226, %ptr %r227)
	%r229 = getelementptr [2 x i8], [2 x i8]* @str1233, %word 0, %word 0
	%r231 = bitcast %ptr (%ptr, %ptr)* @"subr/&" to %ptr
	%r232 = inttoptr %word 0 to %ptr
	%r233 = load %ptr, %ptr* %t1
	%r234 = call %ptr @"%instantiate-subr"(%ptr %r229, %ptr %r231, %ptr %r232, %ptr %r233)
	%r235 = getelementptr [2 x i8], [2 x i8]* @str1234, %word 0, %word 0
	%r237 = bitcast %ptr (%ptr, %ptr)* @"subr/|" to %ptr
	%r238 = inttoptr %word 0 to %ptr
	%r239 = load %ptr, %ptr* %t1
	%r240 = call %ptr @"%instantiate-subr"(%ptr %r235, %ptr %r237, %ptr %r238, %ptr %r239)
	%r241 = getelementptr [2 x i8], [2 x i8]* @str1235, %word 0, %word 0
	%r243 = bitcast %ptr (%ptr, %ptr)* @"subr/^" to %ptr
	%r244 = inttoptr %word 0 to %ptr
	%r245 = load %ptr, %ptr* %t1
	%r246 = call %ptr @"%instantiate-subr"(%ptr %r241, %ptr %r243, %ptr %r244, %ptr %r245)
	%r247 = getelementptr [2 x i8], [2 x i8]* @str1236, %word 0, %word 0
	%r249 = bitcast %ptr (%ptr, %ptr)* @"subr/+" to %ptr
	%r250 = inttoptr %word 0 to %ptr
	%r251 = load %ptr, %ptr* %t1
	%r252 = call %ptr @"%instantiate-subr"(%ptr %r247, %ptr %r249, %ptr %r250, %ptr %r251)
	%r253 = getelementptr [2 x i8], [2 x i8]* @str1237, %word 0, %word 0
	%r255 = bitcast %ptr (%ptr, %ptr)* @"subr/*" to %ptr
	%r256 = inttoptr %word 0 to %ptr
	%r257 = load %ptr, %ptr* %t1
	%r258 = call %ptr @"%instantiate-subr"(%ptr %r253, %ptr %r255, %ptr %r256, %ptr %r257)
	%r259 = getelementptr [2 x i8], [2 x i8]* @str1238, %word 0, %word 0
	%r261 = bitcast %ptr (%ptr, %ptr)* @"subr//" to %ptr
	%r262 = inttoptr %word 0 to %ptr
	%r263 = load %ptr, %ptr* %t1
	%r264 = call %ptr @"%instantiate-subr"(%ptr %r259, %ptr %r261, %ptr %r262, %ptr %r263)
	%r265 = getelementptr [3 x i8], [3 x i8]* @str1239, %word 0, %word 0
	%r267 = bitcast %ptr (%ptr, %ptr)* @"subr/<<" to %ptr
	%r268 = inttoptr %word 0 to %ptr
	%r269 = load %ptr, %ptr* %t1
	%r270 = call %ptr @"%instantiate-subr"(%ptr %r265, %ptr %r267, %ptr %r268, %ptr %r269)
	%r271 = getelementptr [3 x i8], [3 x i8]* @str1240, %word 0, %word 0
	%r273 = bitcast %ptr (%ptr, %ptr)* @"subr/>>" to %ptr
	%r274 = inttoptr %word 0 to %ptr
	%r275 = load %ptr, %ptr* %t1
	%r276 = call %ptr @"%instantiate-subr"(%ptr %r271, %ptr %r273, %ptr %r274, %ptr %r275)
	%r277 = getelementptr [2 x i8], [2 x i8]* @str1241, %word 0, %word 0
	%r279 = bitcast %ptr (%ptr, %ptr)* @"subr/<" to %ptr
	%r280 = inttoptr %word 0 to %ptr
	%r281 = load %ptr, %ptr* %t1
	%r282 = call %ptr @"%instantiate-subr"(%ptr %r277, %ptr %r279, %ptr %r280, %ptr %r281)
	%r283 = getelementptr [3 x i8], [3 x i8]* @str1242, %word 0, %word 0
	%r285 = bitcast %ptr (%ptr, %ptr)* @"subr/<=" to %ptr
	%r286 = inttoptr %word 0 to %ptr
	%r287 = load %ptr, %ptr* %t1
	%r288 = call %ptr @"%instantiate-subr"(%ptr %r283, %ptr %r285, %ptr %r286, %ptr %r287)
	%r289 = getelementptr [3 x i8], [3 x i8]* @str1243, %word 0, %word 0
	%r291 = bitcast %ptr (%ptr, %ptr)* @"subr/>=" to %ptr
	%r292 = inttoptr %word 0 to %ptr
	%r293 = load %ptr, %ptr* %t1
	%r294 = call %ptr @"%instantiate-subr"(%ptr %r289, %ptr %r291, %ptr %r292, %ptr %r293)
	%r295 = getelementptr [2 x i8], [2 x i8]* @str1244, %word 0, %word 0
	%r297 = bitcast %ptr (%ptr, %ptr)* @"subr/>" to %ptr
	%r298 = inttoptr %word 0 to %ptr
	%r299 = load %ptr, %ptr* %t1
	%r300 = call %ptr @"%instantiate-subr"(%ptr %r295, %ptr %r297, %ptr %r298, %ptr %r299)
	%r301 = getelementptr [2 x i8], [2 x i8]* @str1245, %word 0, %word 0
	%r303 = bitcast %ptr (%ptr, %ptr)* @"subr/=" to %ptr
	%r304 = inttoptr %word 0 to %ptr
	%r305 = load %ptr, %ptr* %t1
	%r306 = call %ptr @"%instantiate-subr"(%ptr %r301, %ptr %r303, %ptr %r304, %ptr %r305)
	%r307 = getelementptr [3 x i8], [3 x i8]* @str1246, %word 0, %word 0
	%r309 = bitcast %ptr (%ptr, %ptr)* @"subr/!=" to %ptr
	%r310 = inttoptr %word 0 to %ptr
	%r311 = load %ptr, %ptr* %t1
	%r312 = call %ptr @"%instantiate-subr"(%ptr %r307, %ptr %r309, %ptr %r310, %ptr %r311)
	%r313 = getelementptr [6 x i8], [6 x i8]* @str1247, %word 0, %word 0
	%r315 = bitcast %ptr (%ptr, %ptr)* @"subr/abort" to %ptr
	%r316 = inttoptr %word 0 to %ptr
	%r317 = load %ptr, %ptr* %t1
	%r318 = call %ptr @"%instantiate-subr"(%ptr %r313, %ptr %r315, %ptr %r316, %ptr %r317)
	%r319 = getelementptr [5 x i8], [5 x i8]* @str1248, %word 0, %word 0
	%r321 = bitcast %ptr (%ptr, %ptr)* @"subr/exit" to %ptr
	%r322 = inttoptr %word 0 to %ptr
	%r323 = load %ptr, %ptr* %t1
	%r324 = call %ptr @"%instantiate-subr"(%ptr %r319, %ptr %r321, %ptr %r322, %ptr %r323)
	%r325 = getelementptr [11 x i8], [11 x i8]* @str1249, %word 0, %word 0
	%r327 = bitcast %ptr (%ptr, %ptr)* @"subr/libc/fopen" to %ptr
	%r328 = inttoptr %word 0 to %ptr
	%r329 = load %ptr, %ptr* %t1
	%r330 = call %ptr @"%instantiate-subr"(%ptr %r325, %ptr %r327, %ptr %r328, %ptr %r329)
	%r331 = getelementptr [12 x i8], [12 x i8]* @str1250, %word 0, %word 0
	%r333 = bitcast %ptr (%ptr, %ptr)* @"subr/libc/fclose" to %ptr
	%r334 = inttoptr %word 0 to %ptr
	%r335 = load %ptr, %ptr* %t1
	%r336 = call %ptr @"%instantiate-subr"(%ptr %r331, %ptr %r333, %ptr %r334, %ptr %r335)
	%r337 = getelementptr [11 x i8], [11 x i8]* @str1251, %word 0, %word 0
	%r339 = bitcast %ptr (%ptr, %ptr)* @"subr/libc/fgetc" to %ptr
	%r340 = inttoptr %word 0 to %ptr
	%r341 = load %ptr, %ptr* %t1
	%r342 = call %ptr @"%instantiate-subr"(%ptr %r337, %ptr %r339, %ptr %r340, %ptr %r341)
	%r343 = getelementptr [11 x i8], [11 x i8]* @str1252, %word 0, %word 0
	%r345 = bitcast %ptr (%ptr, %ptr)* @"subr/libc/fputc" to %ptr
	%r346 = inttoptr %word 0 to %ptr
	%r347 = load %ptr, %ptr* %t1
	%r348 = call %ptr @"%instantiate-subr"(%ptr %r343, %ptr %r345, %ptr %r346, %ptr %r347)
	%r349 = getelementptr [12 x i8], [12 x i8]* @str1253, %word 0, %word 0
	%r351 = bitcast %ptr (%ptr, %ptr)* @"subr/libc/format" to %ptr
	%r352 = inttoptr %word 0 to %ptr
	%r353 = load %ptr, %ptr* %t1
	%r354 = call %ptr @"%instantiate-subr"(%ptr %r349, %ptr %r351, %ptr %r352, %ptr %r353)
	%r355 = getelementptr [12 x i8], [12 x i8]* @str1254, %word 0, %word 0
	%r357 = bitcast %ptr (%ptr, %ptr)* @"subr/repl-stream" to %ptr
	%r358 = inttoptr %word 0 to %ptr
	%r359 = load %ptr, %ptr* %t1
	%r360 = call %ptr @"%instantiate-subr"(%ptr %r355, %ptr %r357, %ptr %r358, %ptr %r359)
	%r361 = getelementptr [5 x i8], [5 x i8]* @str1255, %word 0, %word 0
	%r363 = bitcast %ptr (%ptr, %ptr)* @"subr/dump" to %ptr
	%r364 = inttoptr %word 0 to %ptr
	%r365 = load %ptr, %ptr* %t1
	%r366 = call %ptr @"%instantiate-subr"(%ptr %r361, %ptr %r363, %ptr %r364, %ptr %r365)
	%r367 = getelementptr [6 x i8], [6 x i8]* @str1256, %word 0, %word 0
	%r369 = bitcast %ptr (%ptr, %ptr)* @"subr/print" to %ptr
	%r370 = inttoptr %word 0 to %ptr
	%r371 = load %ptr, %ptr* %t1
	%r372 = call %ptr @"%instantiate-subr"(%ptr %r367, %ptr %r369, %ptr %r370, %ptr %r371)
	%r373 = getelementptr [5 x i8], [5 x i8]* @str1257, %word 0, %word 0
	%r375 = bitcast %ptr (%ptr, %ptr)* @"subr/warn" to %ptr
	%r376 = inttoptr %word 0 to %ptr
	%r377 = load %ptr, %ptr* %t1
	%r378 = call %ptr @"%instantiate-subr"(%ptr %r373, %ptr %r375, %ptr %r376, %ptr %r377)
	%r379 = getelementptr [6 x i8], [6 x i8]* @str1258, %word 0, %word 0
	%r381 = bitcast %ptr (%ptr, %ptr)* @"subr/apply" to %ptr
	%r382 = inttoptr %word 0 to %ptr
	%r383 = load %ptr, %ptr* %t1
	%r384 = call %ptr @"%instantiate-subr"(%ptr %r379, %ptr %r381, %ptr %r382, %ptr %r383)
	%r385 = getelementptr [5 x i8], [5 x i8]* @str1259, %word 0, %word 0
	%r387 = bitcast %ptr (%ptr, %ptr)* @"subr/eval" to %ptr
	%r388 = inttoptr %word 0 to %ptr
	%r389 = load %ptr, %ptr* %t1
	%r390 = call %ptr @"%instantiate-subr"(%ptr %r385, %ptr %r387, %ptr %r388, %ptr %r389)
	%r391 = getelementptr [7 x i8], [7 x i8]* @str1260, %word 0, %word 0
	%r393 = bitcast %ptr (%ptr, %ptr)* @"subr/encode" to %ptr
	%r394 = inttoptr %word 0 to %ptr
	%r395 = load %ptr, %ptr* %t1
	%r396 = call %ptr @"%instantiate-subr"(%ptr %r391, %ptr %r393, %ptr %r394, %ptr %r395)
	%r397 = getelementptr [7 x i8], [7 x i8]* @str1261, %word 0, %word 0
	%r399 = bitcast %ptr (%ptr, %ptr)* @"subr/expand" to %ptr
	%r400 = inttoptr %word 0 to %ptr
	%r401 = load %ptr, %ptr* %t1
	%r402 = call %ptr @"%instantiate-subr"(%ptr %r397, %ptr %r399, %ptr %r400, %ptr %r401)
	%r403 = getelementptr [5 x i8], [5 x i8]* @str1262, %word 0, %word 0
	%r405 = bitcast %ptr (%ptr, %ptr)* @"subr/cons" to %ptr
	%r406 = inttoptr %word 0 to %ptr
	%r407 = load %ptr, %ptr* %t1
	%r408 = call %ptr @"%instantiate-subr"(%ptr %r403, %ptr %r405, %ptr %r406, %ptr %r407)
	%r409 = getelementptr [7 x i8], [7 x i8]* @str1263, %word 0, %word 0
	%r411 = bitcast %ptr (%ptr, %ptr)* @"subr/string" to %ptr
	%r412 = inttoptr %word 0 to %ptr
	%r413 = load %ptr, %ptr* %t1
	%r414 = call %ptr @"%instantiate-subr"(%ptr %r409, %ptr %r411, %ptr %r412, %ptr %r413)
	%r415 = getelementptr [6 x i8], [6 x i8]* @str1264, %word 0, %word 0
	%r417 = bitcast %ptr (%ptr, %ptr)* @"subr/array" to %ptr
	%r418 = inttoptr %word 0 to %ptr
	%r419 = load %ptr, %ptr* %t1
	%r420 = call %ptr @"%instantiate-subr"(%ptr %r415, %ptr %r417, %ptr %r418, %ptr %r419)
	%r421 = getelementptr [5 x i8], [5 x i8]* @str1265, %word 0, %word 0
	%r423 = bitcast %ptr (%ptr, %ptr)* @"subr/form" to %ptr
	%r424 = inttoptr %word 0 to %ptr
	%r425 = load %ptr, %ptr* %t1
	%r426 = call %ptr @"%instantiate-subr"(%ptr %r421, %ptr %r423, %ptr %r424, %ptr %r425)
	%r427 = getelementptr [9 x i8], [9 x i8]* @str1266, %word 0, %word 0
	%r429 = bitcast %ptr (%ptr, %ptr)* @"subr/allocate" to %ptr
	%r430 = inttoptr %word 0 to %ptr
	%r431 = load %ptr, %ptr* %t1
	%r432 = call %ptr @"%instantiate-subr"(%ptr %r427, %ptr %r429, %ptr %r430, %ptr %r431)
	%r433 = getelementptr [8 x i8], [8 x i8]* @str1267, %word 0, %word 0
	%r435 = bitcast %ptr (%ptr, %ptr)* @"subr/type-of" to %ptr
	%r436 = inttoptr %word 0 to %ptr
	%r437 = load %ptr, %ptr* %t1
	%r438 = call %ptr @"%instantiate-subr"(%ptr %r433, %ptr %r435, %ptr %r436, %ptr %r437)
	%r439 = getelementptr [8 x i8], [8 x i8]* @str1268, %word 0, %word 0
	%r441 = bitcast %ptr (%ptr, %ptr)* @"subr/string?" to %ptr
	%r442 = inttoptr %word 0 to %ptr
	%r443 = load %ptr, %ptr* %t1
	%r444 = call %ptr @"%instantiate-subr"(%ptr %r439, %ptr %r441, %ptr %r442, %ptr %r443)
	%r445 = getelementptr [8 x i8], [8 x i8]* @str1269, %word 0, %word 0
	%r447 = bitcast %ptr (%ptr, %ptr)* @"subr/symbol?" to %ptr
	%r448 = inttoptr %word 0 to %ptr
	%r449 = load %ptr, %ptr* %t1
	%r450 = call %ptr @"%instantiate-subr"(%ptr %r445, %ptr %r447, %ptr %r448, %ptr %r449)
	%r451 = getelementptr [6 x i8], [6 x i8]* @str1270, %word 0, %word 0
	%r453 = bitcast %ptr (%ptr, %ptr)* @"subr/pair?" to %ptr
	%r454 = inttoptr %word 0 to %ptr
	%r455 = load %ptr, %ptr* %t1
	%r456 = call %ptr @"%instantiate-subr"(%ptr %r451, %ptr %r453, %ptr %r454, %ptr %r455)
	%r457 = getelementptr [7 x i8], [7 x i8]* @str1271, %word 0, %word 0
	%r459 = bitcast %ptr (%ptr, %ptr)* @"subr/array?" to %ptr
	%r460 = inttoptr %word 0 to %ptr
	%r461 = load %ptr, %ptr* %t1
	%r462 = call %ptr @"%instantiate-subr"(%ptr %r457, %ptr %r459, %ptr %r460, %ptr %r461)
	%r463 = getelementptr [4 x i8], [4 x i8]* @str1272, %word 0, %word 0
	%r465 = bitcast %ptr (%ptr, %ptr)* @"subr/car" to %ptr
	%r466 = inttoptr %word 0 to %ptr
	%r467 = load %ptr, %ptr* %t1
	%r468 = call %ptr @"%instantiate-subr"(%ptr %r463, %ptr %r465, %ptr %r466, %ptr %r467)
	%r469 = getelementptr [4 x i8], [4 x i8]* @str1273, %word 0, %word 0
	%r471 = bitcast %ptr (%ptr, %ptr)* @"subr/cdr" to %ptr
	%r472 = inttoptr %word 0 to %ptr
	%r473 = load %ptr, %ptr* %t1
	%r474 = call %ptr @"%instantiate-subr"(%ptr %r469, %ptr %r471, %ptr %r472, %ptr %r473)
	%r475 = getelementptr [8 x i8], [8 x i8]* @str1274, %word 0, %word 0
	%r477 = bitcast %ptr (%ptr, %ptr)* @"subr/set-car" to %ptr
	%r478 = inttoptr %word 0 to %ptr
	%r479 = load %ptr, %ptr* %t1
	%r480 = call %ptr @"%instantiate-subr"(%ptr %r475, %ptr %r477, %ptr %r478, %ptr %r479)
	%r481 = getelementptr [8 x i8], [8 x i8]* @str1275, %word 0, %word 0
	%r483 = bitcast %ptr (%ptr, %ptr)* @"subr/set-cdr" to %ptr
	%r484 = inttoptr %word 0 to %ptr
	%r485 = load %ptr, %ptr* %t1
	%r486 = call %ptr @"%instantiate-subr"(%ptr %r481, %ptr %r483, %ptr %r484, %ptr %r485)
	%r487 = getelementptr [7 x i8], [7 x i8]* @str1276, %word 0, %word 0
	%r489 = bitcast %ptr (%ptr, %ptr)* @"subr/oop-at" to %ptr
	%r490 = inttoptr %word 0 to %ptr
	%r491 = load %ptr, %ptr* %t1
	%r492 = call %ptr @"%instantiate-subr"(%ptr %r487, %ptr %r489, %ptr %r490, %ptr %r491)
	%r493 = getelementptr [11 x i8], [11 x i8]* @str1277, %word 0, %word 0
	%r495 = bitcast %ptr (%ptr, %ptr)* @"subr/set-oop-at" to %ptr
	%r496 = inttoptr %word 0 to %ptr
	%r497 = load %ptr, %ptr* %t1
	%r498 = call %ptr @"%instantiate-subr"(%ptr %r493, %ptr %r495, %ptr %r496, %ptr %r497)
	%r499 = getelementptr [13 x i8], [13 x i8]* @str1278, %word 0, %word 0
	%r501 = bitcast %ptr (%ptr, %ptr)* @"subr/array-length" to %ptr
	%r502 = inttoptr %word 0 to %ptr
	%r503 = load %ptr, %ptr* %t1
	%r504 = call %ptr @"%instantiate-subr"(%ptr %r499, %ptr %r501, %ptr %r502, %ptr %r503)
	%r505 = getelementptr [9 x i8], [9 x i8]* @str1279, %word 0, %word 0
	%r507 = bitcast %ptr (%ptr, %ptr)* @"subr/array-at" to %ptr
	%r508 = inttoptr %word 0 to %ptr
	%r509 = load %ptr, %ptr* %t1
	%r510 = call %ptr @"%instantiate-subr"(%ptr %r505, %ptr %r507, %ptr %r508, %ptr %r509)
	%r511 = getelementptr [13 x i8], [13 x i8]* @str1280, %word 0, %word 0
	%r513 = bitcast %ptr (%ptr, %ptr)* @"subr/set-array-at" to %ptr
	%r514 = inttoptr %word 0 to %ptr
	%r515 = load %ptr, %ptr* %t1
	%r516 = call %ptr @"%instantiate-subr"(%ptr %r511, %ptr %r513, %ptr %r514, %ptr %r515)
	%r517 = getelementptr [13 x i8], [13 x i8]* @str1281, %word 0, %word 0
	%r519 = bitcast %ptr (%ptr, %ptr)* @"subr/array-insert" to %ptr
	%r520 = inttoptr %word 0 to %ptr
	%r521 = load %ptr, %ptr* %t1
	%r522 = call %ptr @"%instantiate-subr"(%ptr %r517, %ptr %r519, %ptr %r520, %ptr %r521)
	%r523 = getelementptr [14 x i8], [14 x i8]* @str1282, %word 0, %word 0
	%r525 = bitcast %ptr (%ptr, %ptr)* @"subr/string-length" to %ptr
	%r526 = inttoptr %word 0 to %ptr
	%r527 = load %ptr, %ptr* %t1
	%r528 = call %ptr @"%instantiate-subr"(%ptr %r523, %ptr %r525, %ptr %r526, %ptr %r527)
	%r529 = getelementptr [10 x i8], [10 x i8]* @str1283, %word 0, %word 0
	%r531 = bitcast %ptr (%ptr, %ptr)* @"subr/string-at" to %ptr
	%r532 = inttoptr %word 0 to %ptr
	%r533 = load %ptr, %ptr* %t1
	%r534 = call %ptr @"%instantiate-subr"(%ptr %r529, %ptr %r531, %ptr %r532, %ptr %r533)
	%r535 = getelementptr [14 x i8], [14 x i8]* @str1284, %word 0, %word 0
	%r537 = bitcast %ptr (%ptr, %ptr)* @"subr/set-string-at" to %ptr
	%r538 = inttoptr %word 0 to %ptr
	%r539 = load %ptr, %ptr* %t1
	%r540 = call %ptr @"%instantiate-subr"(%ptr %r535, %ptr %r537, %ptr %r538, %ptr %r539)
	%r541 = getelementptr [15 x i8], [15 x i8]* @str1285, %word 0, %word 0
	%r543 = bitcast %ptr (%ptr, %ptr)* @"subr/string->symbol" to %ptr
	%r544 = inttoptr %word 0 to %ptr
	%r545 = load %ptr, %ptr* %t1
	%r546 = call %ptr @"%instantiate-subr"(%ptr %r541, %ptr %r543, %ptr %r544, %ptr %r545)
	%r547 = getelementptr [15 x i8], [15 x i8]* @str1286, %word 0, %word 0
	%r549 = bitcast %ptr (%ptr, %ptr)* @"subr/symbol->string" to %ptr
	%r550 = inttoptr %word 0 to %ptr
	%r551 = load %ptr, %ptr* %t1
	%r552 = call %ptr @"%instantiate-subr"(%ptr %r547, %ptr %r549, %ptr %r550, %ptr %r551)
	%r553 = getelementptr [13 x i8], [13 x i8]* @str1287, %word 0, %word 0
	%r555 = bitcast %ptr (%ptr, %ptr)* @"subr/long->string" to %ptr
	%r556 = inttoptr %word 0 to %ptr
	%r557 = load %ptr, %ptr* %t1
	%r558 = call %ptr @"%instantiate-subr"(%ptr %r553, %ptr %r555, %ptr %r556, %ptr %r557)
	%r559 = getelementptr [5 x i8], [5 x i8]* @str1288, %word 0, %word 0
	%r561 = bitcast %ptr (%ptr, %ptr)* @"subr/read" to %ptr
	%r562 = inttoptr %word 0 to %ptr
	%r563 = load %ptr, %ptr* %t1
	%r564 = call %ptr @"%instantiate-subr"(%ptr %r559, %ptr %r561, %ptr %r562, %ptr %r563)
	%r565 = getelementptr [15 x i8], [15 x i8]* @str1289, %word 0, %word 0
	%r567 = bitcast %ptr (%ptr, %ptr)* @"subr/current-module" to %ptr
	%r568 = inttoptr %word 0 to %ptr
	%r569 = load %ptr, %ptr* %t1
	%r570 = call %ptr @"%instantiate-subr"(%ptr %r565, %ptr %r567, %ptr %r568, %ptr %r569)
	%r571 = getelementptr [19 x i8], [19 x i8]* @str1290, %word 0, %word 0
	%r573 = bitcast %ptr (%ptr, %ptr)* @"subr/set-current-module" to %ptr
	%r574 = inttoptr %word 0 to %ptr
	%r575 = load %ptr, %ptr* %t1
	%r576 = call %ptr @"%instantiate-subr"(%ptr %r571, %ptr %r573, %ptr %r574, %ptr %r575)
	%r577 = getelementptr [14 x i8], [14 x i8]* @str1291, %word 0, %word 0
	%r579 = bitcast %ptr (%ptr, %ptr)* @"subr/create-module" to %ptr
	%r580 = inttoptr %word 0 to %ptr
	%r581 = load %ptr, %ptr* %t1
	%r582 = call %ptr @"%instantiate-subr"(%ptr %r577, %ptr %r579, %ptr %r580, %ptr %r581)
	%r583 = getelementptr [15 x i8], [15 x i8]* @str1292, %word 0, %word 0
	%r585 = bitcast %ptr (%ptr, %ptr)* @"subr/eval-in-module" to %ptr
	%r586 = inttoptr %word 0 to %ptr
	%r587 = load %ptr, %ptr* %t1
	%r588 = call %ptr @"%instantiate-subr"(%ptr %r583, %ptr %r585, %ptr %r586, %ptr %r587)
	ret %ptr %r588
}
define %ptr @"k/set-current-module"(%ptr %module) {
	%t1 = alloca %ptr
	store %ptr %module, %ptr* %t1
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	store %ptr %r2, %ptr* @"*module*"
	%r3 = call %ptr @capture-well-known-vm-values()
	ret %ptr %r3
}
define %ptr @"subr/set-current-module"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = inttoptr %word 0 to %ptr
	%r5 = load %ptr, %ptr* %t3
	%r6 = call %ptr @"k/set-current-module"(%ptr %r5)
	%r7 = inttoptr %word 0 to %ptr
	ret %ptr %r7
}
define %ptr @"subr/create-module"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t4 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = call %ptr @"new-<module>"()
	store %ptr %r2, %ptr* %t3
	%r4 = getelementptr %ptr, %ptr* %t3, %word 0
	%r3 = bitcast %ptr* %r4 to %ptr
	%r5 = call %ptr @"gc/push-root"(%ptr %r3)
	%r6 = load %ptr, %ptr* %t3
	%r7 = call %ptr @populate-module-with-primitives(%ptr %r6)
	%r8 = load %ptr, %ptr* %t3
	store %ptr %r8, %ptr* %t4
	%r10 = getelementptr %ptr, %ptr* %t3, %word 0
	%r9 = bitcast %ptr* %r10 to %ptr
	%r11 = call %ptr @"gc/pop-root"(%ptr %r9)
	%r12 = load %ptr, %ptr* %t4
	ret %ptr %r12
}
define %ptr @"subr/eval-in-module"(%ptr %-args-, %ptr %-ctx-) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t6 = alloca %ptr
	%t7 = alloca %ptr
	store %ptr %-args-, %ptr* %t1
	store %ptr %-ctx-, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"k/car"(%ptr %r2)
	store %ptr %r3, %ptr* %t3
	%r4 = load %ptr, %ptr* %t1
	%r5 = call %ptr @"k/cadr"(%ptr %r4)
	store %ptr %r5, %ptr* %t4
	%r6 = load %ptr, %ptr* @"*module*"
	store %ptr %r6, %ptr* %t5
	%r7 = inttoptr %word 0 to %ptr
	%r8 = inttoptr %word 0 to %ptr
	%r9 = load %ptr, %ptr* %t3
	%r10 = call %ptr @"k/set-current-module"(%ptr %r9)
	%r11 = load %ptr, %ptr* %t4
	%r12 = load %ptr, %ptr* %t3
	store %ptr %r12, %ptr* %t6
	%r13 = inttoptr %word 0 to %ptr
	%r14 = inttoptr %word 1 to %ptr
	%r15 = load %ptr, %ptr* %t6
	%r19 = bitcast %ptr %r15 to [0 x %ptr]*
	%r18 = ptrtoint %ptr %r14 to %word
	%r17 = getelementptr [0 x %ptr], [0 x %ptr]* %r19, %word 0, %word %r18
	%r16 = load %ptr, %ptr* %r17
	store %ptr %r16, %ptr* %t6
	%r20 = inttoptr %word 0 to %ptr
	%r21 = inttoptr %word 1 to %ptr
	%r22 = load %ptr, %ptr* %t6
	%r26 = bitcast %ptr %r22 to [0 x %ptr]*
	%r25 = ptrtoint %ptr %r21 to %word
	%r24 = getelementptr [0 x %ptr], [0 x %ptr]* %r26, %word 0, %word %r25
	%r23 = load %ptr, %ptr* %r24
	%r27 = call %ptr @"k/expand-encode-eval"(%ptr %r11, %ptr %r23)
	store %ptr %r27, %ptr* %t6
	%r29 = getelementptr %ptr, %ptr* %t6, %word 0
	%r28 = bitcast %ptr* %r29 to %ptr
	%r30 = call %ptr @"gc/push-root"(%ptr %r28)
	%r31 = load %ptr, %ptr* %t5
	%r32 = call %ptr @"k/set-current-module"(%ptr %r31)
	%r33 = inttoptr %word 0 to %ptr
	%r34 = load %ptr, %ptr* %t6
	store %ptr %r34, %ptr* %t7
	%r36 = getelementptr %ptr, %ptr* %t6, %word 0
	%r35 = bitcast %ptr* %r36 to %ptr
	%r37 = call %ptr @"gc/pop-root"(%ptr %r35)
	%r38 = load %ptr, %ptr* %t7
	ret %ptr %r38
}
define %ptr @"%instantiate-subr"(%ptr %name, %ptr %imp, %ptr %"fixed?", %ptr %module) {
	%t4 = alloca %ptr
	%t3 = alloca %ptr
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t5 = alloca %ptr
	%t6 = alloca %ptr
	store %ptr %name, %ptr* %t1
	store %ptr %imp, %ptr* %t2
	store %ptr %"fixed?", %ptr* %t3
	store %ptr %module, %ptr* %t4
	%r1 = load %ptr, %ptr* %t2
	%r2 = load %ptr, %ptr* %t1
	%r3 = call %ptr @"new-<subr>"(%ptr %r1, %ptr %r2)
	store %ptr %r3, %ptr* %t5
	%r5 = getelementptr %ptr, %ptr* %t5, %word 0
	%r4 = bitcast %ptr* %r5 to %ptr
	%r6 = call %ptr @"gc/push-root"(%ptr %r4)
	%r7 = inttoptr %word 1 to %ptr
	store %ptr %r7, %ptr* %t6
	%r8 = load %ptr, %ptr* %t3
	store %ptr %r8, %ptr* %t6
	%r9 = inttoptr %word 0 to %ptr
	%r13 = ptrtoint %ptr %r9 to %word
	%r12 = ptrtoint %ptr %r8 to %word
	%r11 = icmp eq %word %r13, %r12
	%r10 = inttoptr i1 %r11 to %ptr
	%r15 = ptrtoint %ptr %r10 to %word
	%r14 = icmp ne %word %r15, 0
	br i1 %r14, label %L1293, label %L1294
L1294:
	%r16 = load %ptr, %ptr* %t5
	%r17 = call %ptr @"new-<fixed>"(%ptr %r16)
	store %ptr %r17, %ptr* %t5
	store %ptr %r17, %ptr* %t6
	%r18 = inttoptr %word 0 to %ptr
	%r22 = ptrtoint %ptr %r18 to %word
	%r21 = ptrtoint %ptr %r17 to %word
	%r20 = icmp eq %word %r22, %r21
	%r19 = inttoptr i1 %r20 to %ptr
	%r24 = ptrtoint %ptr %r19 to %word
	%r23 = icmp ne %word %r24, 0
	br i1 %r23, label %L1293, label %L1295
L1295:
	br label %L1293
L1293:
	%r25 = load %ptr, %ptr* %t6
	%r26 = load %ptr, %ptr* %t4
	store %ptr %r26, %ptr* %t6
	%r27 = inttoptr %word 0 to %ptr
	%r28 = inttoptr %word 1 to %ptr
	%r29 = load %ptr, %ptr* %t6
	%r33 = bitcast %ptr %r29 to [0 x %ptr]*
	%r32 = ptrtoint %ptr %r28 to %word
	%r31 = getelementptr [0 x %ptr], [0 x %ptr]* %r33, %word 0, %word %r32
	%r30 = load %ptr, %ptr* %r31
	store %ptr %r30, %ptr* %t6
	%r34 = inttoptr %word 0 to %ptr
	%r35 = inttoptr %word 1 to %ptr
	%r36 = load %ptr, %ptr* %t6
	%r40 = bitcast %ptr %r36 to [0 x %ptr]*
	%r39 = ptrtoint %ptr %r35 to %word
	%r38 = getelementptr [0 x %ptr], [0 x %ptr]* %r40, %word 0, %word %r39
	%r37 = load %ptr, %ptr* %r38
	%r41 = load %ptr, %ptr* %t1
	%r42 = load %ptr, %ptr* %t4
	%r43 = call %ptr @"intern*"(%ptr %r41, %ptr %r42)
	%r44 = load %ptr, %ptr* %t5
	%r45 = call %ptr @"k/env/define"(%ptr %r37, %ptr %r43, %ptr %r44)
	store %ptr %r45, %ptr* %t6
	%r47 = getelementptr %ptr, %ptr* %t5, %word 0
	%r46 = bitcast %ptr* %r47 to %ptr
	%r48 = call %ptr @"gc/pop-root"(%ptr %r46)
	%r49 = load %ptr, %ptr* %t6
	ret %ptr %r49
}
@str1296 = private unnamed_addr constant [2 x i8] c"r\00"
@str1297 = private unnamed_addr constant [2 x i8] c"a\00"
@str1298 = private unnamed_addr constant [2 x i8] c"a\00"
@str1301 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str1302 = private unnamed_addr constant [30 x i8] c"get/type for <long> is broken\00"
@str1303 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str1307 = private unnamed_addr constant [9 x i8] c"\0Aerror: \00"
@str1308 = private unnamed_addr constant [19 x i8] c"get/long is broken\00"
@str1309 = private unnamed_addr constant [2 x i8] c"\0A\00"
@str1311 = private unnamed_addr constant [7 x i8] c"+done+\00"
@str1312 = private unnamed_addr constant [25 x i8] c"*command-line-arguments*\00"
@str1322 = private unnamed_addr constant [3 x i8] c"-v\00"
@str1323 = private unnamed_addr constant [12 x i8] c"*verbosity*\00"
@str1327 = private unnamed_addr constant [3 x i8] c"-O\00"
@str1328 = private unnamed_addr constant [12 x i8] c"*optimised*\00"
@str1332 = private unnamed_addr constant [2 x i8] c"-\00"
@str1336 = private unnamed_addr constant [7 x i8] c"--call\00"
@str1339 = private unnamed_addr constant [28 x i8] c"--call requires an argument\00"
@str1344 = private unnamed_addr constant [9 x i8] c"--define\00"
@str1350 = private unnamed_addr constant [32 x i8] c"--define requires two arguments\00"
@str1355 = private unnamed_addr constant [2 x i8] c"r\00"
@str1358 = private unnamed_addr constant [17 x i8] c"no such file: %s\00"
@str1362 = private unnamed_addr constant [37 x i8] c"GC: %d objects in %d bytes, %d free\0A\00"
@str1364 = private unnamed_addr constant [33 x i8] c"%d objects in %d bytes, %d free\0A\00"
define %ptr @main(%ptr %argc, %ptr %argv) {
	%t2 = alloca %ptr
	%t1 = alloca %ptr
	%t3 = alloca %ptr
	%t5 = alloca %ptr
	%t4 = alloca %ptr
	%t7 = alloca %ptr
	%t6 = alloca %ptr
	%t8 = alloca %ptr
	%t9 = alloca %ptr
	%t10 = alloca %ptr
	%t11 = alloca %ptr
	%t12 = alloca %ptr
	%t14 = alloca %ptr
	%t13 = alloca %ptr
	%t15 = alloca %ptr
	%t16 = alloca %ptr
	%t17 = alloca %ptr
	%t18 = alloca %ptr
	store %ptr %argc, %ptr* %t1
	store %ptr %argv, %ptr* %t2
	%r1 = inttoptr %word 0 to %ptr
	%r2 = inttoptr %word 0 to %ptr
	%r3 = getelementptr [2 x i8], [2 x i8]* @str1296, %word 0, %word 0
	%ffi-cast5 = ptrtoint %ptr %r2 to i32
	%r6 = call %ptr @fdopen(i32 %ffi-cast5, %ptr %r3)
	store %ptr %r6, %ptr* @"libc/stdin"
	%r7 = inttoptr %word 1 to %ptr
	%r8 = getelementptr [2 x i8], [2 x i8]* @str1297, %word 0, %word 0
	%ffi-cast10 = ptrtoint %ptr %r7 to i32
	%r11 = call %ptr @fdopen(i32 %ffi-cast10, %ptr %r8)
	store %ptr %r11, %ptr* @"libc/stdout"
	%r12 = inttoptr %word 2 to %ptr
	%r13 = getelementptr [2 x i8], [2 x i8]* @str1298, %word 0, %word 0
	%ffi-cast15 = ptrtoint %ptr %r12 to i32
	%r16 = call %ptr @fdopen(i32 %ffi-cast15, %ptr %r13)
	store %ptr %r16, %ptr* @"libc/stderr"
	%r17 = load %ptr, %ptr* @"libc/stdout"
	%r18 = inttoptr %word 0 to %ptr
	call void @setbuf(%ptr %r17, %ptr %r18)
	%r20 = inttoptr %word 0 to %ptr
	%r21 = load %ptr, %ptr* @"libc/stderr"
	%r22 = inttoptr %word 0 to %ptr
	call void @setbuf(%ptr %r21, %ptr %r22)
	%r24 = inttoptr %word 0 to %ptr
	%r25 = call %ptr @"gc/initialise"()
	%r26 = inttoptr %word 0 to %ptr
	%r27 = inttoptr %word 0 to %ptr
	%r28 = inttoptr %word 0 to %ptr
	store %ptr %r28, %ptr* %t3
	%r29 = inttoptr %word 1 to %ptr
	%r30 = inttoptr %word 1 to %ptr
	%r31 = inttoptr %word 42 to %ptr
	%r35 = ptrtoint %ptr %r31 to %word
	%r34 = ptrtoint %ptr %r30 to %word
	%r33 = shl %word %r35, %r34
	%r32 = inttoptr %word %r33 to %ptr
	%r39 = ptrtoint %ptr %r32 to %word
	%r38 = ptrtoint %ptr %r29 to %word
	%r37 = add %word %r39, %r38
	%r36 = inttoptr %word %r37 to %ptr
	%r40 = call %ptr @"get/type"(%ptr %r36)
	%r41 = inttoptr %word 6 to %ptr
	%r45 = ptrtoint %ptr %r41 to %word
	%r44 = ptrtoint %ptr %r40 to %word
	%r43 = icmp eq %word %r45, %r44
	%r42 = inttoptr i1 %r43 to %ptr
	store %ptr %r42, %ptr* %t3
	%r46 = inttoptr %word 0 to %ptr
	%r50 = ptrtoint %ptr %r46 to %word
	%r49 = ptrtoint %ptr %r42 to %word
	%r48 = icmp eq %word %r50, %r49
	%r47 = inttoptr i1 %r48 to %ptr
	%r52 = ptrtoint %ptr %r47 to %word
	%r51 = icmp ne %word %r52, 0
	br i1 %r51, label %L1300, label %L1299
L1300:
	%r53 = getelementptr [9 x i8], [9 x i8]* @str1301, %word 0, %word 0
	%r55 = call i32 (%ptr, ...) @printf(%ptr %r53)
	%r56 = inttoptr %word %r55 to %ptr
	%r57 = getelementptr [30 x i8], [30 x i8]* @str1302, %word 0, %word 0
	%r59 = call i32 (%ptr, ...) @printf(%ptr %r57)
	%r60 = inttoptr %word %r59 to %ptr
	%r61 = getelementptr [2 x i8], [2 x i8]* @str1303, %word 0, %word 0
	%r63 = call i32 (%ptr, ...) @printf(%ptr %r61)
	%r64 = inttoptr %word %r63 to %ptr
	%r65 = call %ptr @die()
	store %ptr %r65, %ptr* %t3
	%r66 = inttoptr %word 0 to %ptr
	%r70 = ptrtoint %ptr %r66 to %word
	%r69 = ptrtoint %ptr %r65 to %word
	%r68 = icmp eq %word %r70, %r69
	%r67 = inttoptr i1 %r68 to %ptr
	%r72 = ptrtoint %ptr %r67 to %word
	%r71 = icmp ne %word %r72, 0
	br i1 %r71, label %L1304, label %L1299
L1304:
	br label %L1299
L1299:
	%r73 = load %ptr, %ptr* %t3
	%r74 = inttoptr %word 0 to %ptr
	store %ptr %r74, %ptr* %t3
	%r75 = inttoptr %word 1 to %ptr
	%r76 = inttoptr %word 1 to %ptr
	%r77 = inttoptr %word 1 to %ptr
	%r78 = inttoptr %word 42 to %ptr
	%r82 = ptrtoint %ptr %r78 to %word
	%r81 = ptrtoint %ptr %r77 to %word
	%r80 = shl %word %r82, %r81
	%r79 = inttoptr %word %r80 to %ptr
	%r86 = ptrtoint %ptr %r79 to %word
	%r85 = ptrtoint %ptr %r76 to %word
	%r84 = add %word %r86, %r85
	%r83 = inttoptr %word %r84 to %ptr
	%r90 = ptrtoint %ptr %r83 to %word
	%r89 = ptrtoint %ptr %r75 to %word
	%r88 = ashr %word %r90, %r89
	%r87 = inttoptr %word %r88 to %ptr
	%r91 = inttoptr %word 42 to %ptr
	%r95 = ptrtoint %ptr %r91 to %word
	%r94 = ptrtoint %ptr %r87 to %word
	%r93 = icmp eq %word %r95, %r94
	%r92 = inttoptr i1 %r93 to %ptr
	store %ptr %r92, %ptr* %t3
	%r96 = inttoptr %word 0 to %ptr
	%r100 = ptrtoint %ptr %r96 to %word
	%r99 = ptrtoint %ptr %r92 to %word
	%r98 = icmp eq %word %r100, %r99
	%r97 = inttoptr i1 %r98 to %ptr
	%r102 = ptrtoint %ptr %r97 to %word
	%r101 = icmp ne %word %r102, 0
	br i1 %r101, label %L1306, label %L1305
L1306:
	%r103 = getelementptr [9 x i8], [9 x i8]* @str1307, %word 0, %word 0
	%r105 = call i32 (%ptr, ...) @printf(%ptr %r103)
	%r106 = inttoptr %word %r105 to %ptr
	%r107 = getelementptr [19 x i8], [19 x i8]* @str1308, %word 0, %word 0
	%r109 = call i32 (%ptr, ...) @printf(%ptr %r107)
	%r110 = inttoptr %word %r109 to %ptr
	%r111 = getelementptr [2 x i8], [2 x i8]* @str1309, %word 0, %word 0
	%r113 = call i32 (%ptr, ...) @printf(%ptr %r111)
	%r114 = inttoptr %word %r113 to %ptr
	%r115 = call %ptr @die()
	store %ptr %r115, %ptr* %t3
	%r116 = inttoptr %word 0 to %ptr
	%r120 = ptrtoint %ptr %r116 to %word
	%r119 = ptrtoint %ptr %r115 to %word
	%r118 = icmp eq %word %r120, %r119
	%r117 = inttoptr i1 %r118 to %ptr
	%r122 = ptrtoint %ptr %r117 to %word
	%r121 = icmp ne %word %r122, 0
	br i1 %r121, label %L1310, label %L1305
L1310:
	br label %L1305
L1305:
	%r123 = load %ptr, %ptr* %t3
	%r124 = getelementptr [7 x i8], [7 x i8]* @str1311, %word 0, %word 0
	%r126 = call %ptr @"new-<symbol>"(%ptr %r124)
	store %ptr %r126, %ptr* @"k/+done+"
	%r128 = getelementptr %ptr, %ptr* @"k/+done+", %word 0
	%r127 = bitcast %ptr* %r128 to %ptr
	%r129 = call %ptr @"gc/push-root"(%ptr %r127)
	%r131 = getelementptr %ptr, %ptr* @"*module*", %word 0
	%r130 = bitcast %ptr* %r131 to %ptr
	%r132 = call %ptr @"gc/push-root"(%ptr %r130)
	%r134 = getelementptr %ptr, %ptr* @"*backtrace-stack*", %word 0
	%r133 = bitcast %ptr* %r134 to %ptr
	%r135 = call %ptr @"gc/push-root"(%ptr %r133)
	%r137 = getelementptr %ptr, %ptr* @"fixed-subr/quote", %word 0
	%r136 = bitcast %ptr* %r137 to %ptr
	%r138 = call %ptr @"gc/push-root"(%ptr %r136)
	%r140 = getelementptr %ptr, %ptr* @"fixed-subr/lambda", %word 0
	%r139 = bitcast %ptr* %r140 to %ptr
	%r141 = call %ptr @"gc/push-root"(%ptr %r139)
	%r143 = getelementptr %ptr, %ptr* @"fixed-subr/let", %word 0
	%r142 = bitcast %ptr* %r143 to %ptr
	%r144 = call %ptr @"gc/push-root"(%ptr %r142)
	%r146 = getelementptr %ptr, %ptr* @"fixed-subr/define", %word 0
	%r145 = bitcast %ptr* %r146 to %ptr
	%r147 = call %ptr @"gc/push-root"(%ptr %r145)
	%r148 = inttoptr %word 0 to %ptr
	%r149 = call %ptr @"new-<module>"()
	store %ptr %r149, %ptr* @"*module*"
	%r150 = inttoptr %word 0 to %ptr
	%r151 = inttoptr %word 32 to %ptr
	%r152 = call %ptr @"new-<array>"(%ptr %r151)
	store %ptr %r152, %ptr* @"*backtrace-stack*"
	%r153 = inttoptr %word 0 to %ptr
	%r154 = load %ptr, %ptr* @"*module*"
	%r155 = call %ptr @populate-module-with-primitives(%ptr %r154)
	%r156 = call %ptr @capture-well-known-vm-values()
	%r157 = inttoptr %word 0 to %ptr
	%r158 = load %ptr, %ptr* @"*module*"
	store %ptr %r158, %ptr* %t3
	%r159 = inttoptr %word 0 to %ptr
	%r160 = inttoptr %word 1 to %ptr
	%r161 = load %ptr, %ptr* %t3
	%r165 = bitcast %ptr %r161 to [0 x %ptr]*
	%r164 = ptrtoint %ptr %r160 to %word
	%r163 = getelementptr [0 x %ptr], [0 x %ptr]* %r165, %word 0, %word %r164
	%r162 = load %ptr, %ptr* %r163
	store %ptr %r162, %ptr* %t3
	%r166 = inttoptr %word 0 to %ptr
	%r167 = inttoptr %word 1 to %ptr
	%r168 = load %ptr, %ptr* %t3
	%r172 = bitcast %ptr %r168 to [0 x %ptr]*
	%r171 = ptrtoint %ptr %r167 to %word
	%r170 = getelementptr [0 x %ptr], [0 x %ptr]* %r172, %word 0, %word %r171
	%r169 = load %ptr, %ptr* %r170
	%r173 = getelementptr [25 x i8], [25 x i8]* @str1312, %word 0, %word 0
	%r175 = call %ptr @intern(%ptr %r173)
	%r176 = call %ptr @"k/env/lookup-variable"(%ptr %r169, %ptr %r175)
	store %ptr %r176, %ptr* %t3
	%r177 = inttoptr %word 0 to %ptr
	store %ptr %r177, %ptr* %t4
	%r179 = getelementptr %ptr, %ptr* %t4, %word 0
	%r178 = bitcast %ptr* %r179 to %ptr
	%r180 = call %ptr @"gc/push-root"(%ptr %r178)
	%r181 = load %ptr, %ptr* %t1
	store %ptr %r181, %ptr* %t5
	br label %L1314
L1313:
	%r182 = inttoptr %word 0 to %ptr
	%r183 = load %ptr, %ptr* %t4
	%r184 = call %ptr @"new-<pair>"(%ptr %r182, %ptr %r183)
	store %ptr %r184, %ptr* %t4
	%r185 = load %ptr, %ptr* %t5
	%r186 = load %ptr, %ptr* %t2
	%r190 = bitcast %ptr %r186 to [0 x %ptr]*
	%r189 = ptrtoint %ptr %r185 to %word
	%r188 = getelementptr [0 x %ptr], [0 x %ptr]* %r190, %word 0, %word %r189
	%r187 = load %ptr, %ptr* %r188
	%r191 = call %ptr @"new-<string>-from-cstring"(%ptr %r187)
	%r192 = inttoptr %word 0 to %ptr
	%r193 = load %ptr, %ptr* %t4
	%r197 = bitcast %ptr %r193 to [0 x %ptr]*
	%r196 = ptrtoint %ptr %r192 to %word
	%r195 = getelementptr [0 x %ptr], [0 x %ptr]* %r197, %word 0, %word %r196
	store %ptr %r191, %ptr* %r195
	%r194 = bitcast %ptr %r191 to %ptr
	br label %L1314
L1314:
	%r198 = inttoptr %word 1 to %ptr
	%r199 = load %ptr, %ptr* %t5
	%r203 = ptrtoint %ptr %r199 to %word
	%r202 = ptrtoint %ptr %r198 to %word
	%r201 = sub %word %r203, %r202
	%r200 = inttoptr %word %r201 to %ptr
	store %ptr %r200, %ptr* %t5
	%r204 = inttoptr %word 0 to %ptr
	%r208 = ptrtoint %ptr %r204 to %word
	%r207 = ptrtoint %ptr %r200 to %word
	%r206 = icmp slt %word %r208, %r207
	%r205 = inttoptr i1 %r206 to %ptr
	%r210 = ptrtoint %ptr %r205 to %word
	%r209 = icmp ne %word %r210, 0
	br i1 %r209, label %L1313, label %L1315
L1315:
	%r211 = load %ptr, %ptr* %t3
	store %ptr %r211, %ptr* %t5
	%r212 = inttoptr %word 0 to %ptr
	%r213 = load %ptr, %ptr* %t4
	%r214 = inttoptr %word 1 to %ptr
	%r215 = load %ptr, %ptr* %t5
	%r219 = bitcast %ptr %r215 to [0 x %ptr]*
	%r218 = ptrtoint %ptr %r214 to %word
	%r217 = getelementptr [0 x %ptr], [0 x %ptr]* %r219, %word 0, %word %r218
	store %ptr %r213, %ptr* %r217
	%r216 = bitcast %ptr %r213 to %ptr
	store %ptr %r216, %ptr* %t5
	%r221 = getelementptr %ptr, %ptr* %t4, %word 0
	%r220 = bitcast %ptr* %r221 to %ptr
	%r222 = call %ptr @"gc/pop-root"(%ptr %r220)
	%r223 = load %ptr, %ptr* %t5
	%r224 = inttoptr %word 0 to %ptr
	store %ptr %r224, %ptr* %t4
	%r225 = inttoptr %word 0 to %ptr
	store %ptr %r225, %ptr* %t5
	br label %L1317
L1316:
	%r226 = inttoptr %word 0 to %ptr
	%r227 = load %ptr, %ptr* %t4
	%r231 = bitcast %ptr %r227 to [0 x %ptr]*
	%r230 = ptrtoint %ptr %r226 to %word
	%r229 = getelementptr [0 x %ptr], [0 x %ptr]* %r231, %word 0, %word %r230
	%r228 = load %ptr, %ptr* %r229
	store %ptr %r228, %ptr* %t6
	%r232 = load %ptr, %ptr* %t6
	store %ptr %r232, %ptr* %t7
	%r233 = inttoptr %word 0 to %ptr
	%r234 = inttoptr %word 1 to %ptr
	%r235 = load %ptr, %ptr* %t7
	%r239 = bitcast %ptr %r235 to [0 x %ptr]*
	%r238 = ptrtoint %ptr %r234 to %word
	%r237 = getelementptr [0 x %ptr], [0 x %ptr]* %r239, %word 0, %word %r238
	%r236 = load %ptr, %ptr* %r237
	store %ptr %r236, %ptr* %t7
	%r241 = getelementptr %ptr, %ptr* %t6, %word 0
	%r240 = bitcast %ptr* %r241 to %ptr
	%r242 = call %ptr @"gc/push-root"(%ptr %r240)
	%r244 = getelementptr %ptr, %ptr* %t5, %word 0
	%r243 = bitcast %ptr* %r244 to %ptr
	%r245 = call %ptr @"gc/push-root"(%ptr %r243)
	%r246 = load %ptr, %ptr* %t3
	store %ptr %r246, %ptr* %t8
	%r247 = inttoptr %word 0 to %ptr
	%r248 = inttoptr %word 1 to %ptr
	%r249 = load %ptr, %ptr* %t4
	%r253 = bitcast %ptr %r249 to [0 x %ptr]*
	%r252 = ptrtoint %ptr %r248 to %word
	%r251 = getelementptr [0 x %ptr], [0 x %ptr]* %r253, %word 0, %word %r252
	%r250 = load %ptr, %ptr* %r251
	store %ptr %r250, %ptr* %t4
	%r254 = inttoptr %word 1 to %ptr
	%r255 = load %ptr, %ptr* %t8
	%r259 = bitcast %ptr %r255 to [0 x %ptr]*
	%r258 = ptrtoint %ptr %r254 to %word
	%r257 = getelementptr [0 x %ptr], [0 x %ptr]* %r259, %word 0, %word %r258
	store %ptr %r250, %ptr* %r257
	%r256 = bitcast %ptr %r250 to %ptr
	%r260 = load %ptr, %ptr* %t7
	%r261 = getelementptr [3 x i8], [3 x i8]* @str1322, %word 0, %word 0
	%r263 = call i32 @strcmp(%ptr %r260, %ptr %r261)
	%r264 = inttoptr %word %r263 to %ptr
	%r268 = ptrtoint %ptr %r264 to %word
	%r267 = icmp eq %word %r268, 0
	%r266 = zext i1 %r267 to %word
	%r265 = inttoptr %word %r266 to %ptr
	%r270 = ptrtoint %ptr %r265 to %word
	%r269 = icmp ne %word %r270, 0
	br i1 %r269, label %L1319, label %L1320
L1319:
	%r271 = load %ptr, %ptr* @"*arg/verbose*"
	%r272 = inttoptr %word 1 to %ptr
	%r276 = ptrtoint %ptr %r272 to %word
	%r275 = ptrtoint %ptr %r271 to %word
	%r274 = add %word %r276, %r275
	%r273 = inttoptr %word %r274 to %ptr
	store %ptr %r273, %ptr* @"*arg/verbose*"
	%r277 = inttoptr %word 1 to %ptr
	%r278 = inttoptr %word 1 to %ptr
	%r279 = load %ptr, %ptr* @"*arg/verbose*"
	%r283 = ptrtoint %ptr %r279 to %word
	%r282 = ptrtoint %ptr %r278 to %word
	%r281 = shl %word %r283, %r282
	%r280 = inttoptr %word %r281 to %ptr
	%r287 = ptrtoint %ptr %r280 to %word
	%r286 = ptrtoint %ptr %r277 to %word
	%r285 = add %word %r287, %r286
	%r284 = inttoptr %word %r285 to %ptr
	store %ptr %r284, %ptr* %t5
	%r288 = load %ptr, %ptr* @"*module*"
	store %ptr %r288, %ptr* %t9
	%r289 = inttoptr %word 0 to %ptr
	%r290 = inttoptr %word 1 to %ptr
	%r291 = load %ptr, %ptr* %t9
	%r295 = bitcast %ptr %r291 to [0 x %ptr]*
	%r294 = ptrtoint %ptr %r290 to %word
	%r293 = getelementptr [0 x %ptr], [0 x %ptr]* %r295, %word 0, %word %r294
	%r292 = load %ptr, %ptr* %r293
	store %ptr %r292, %ptr* %t9
	%r296 = inttoptr %word 0 to %ptr
	%r297 = inttoptr %word 1 to %ptr
	%r298 = load %ptr, %ptr* %t9
	%r302 = bitcast %ptr %r298 to [0 x %ptr]*
	%r301 = ptrtoint %ptr %r297 to %word
	%r300 = getelementptr [0 x %ptr], [0 x %ptr]* %r302, %word 0, %word %r301
	%r299 = load %ptr, %ptr* %r300
	%r303 = getelementptr [12 x i8], [12 x i8]* @str1323, %word 0, %word 0
	%r305 = call %ptr @intern(%ptr %r303)
	%r306 = call %ptr @"k/env/lookup-variable"(%ptr %r299, %ptr %r305)
	store %ptr %r306, %ptr* %t9
	%r307 = inttoptr %word 0 to %ptr
	%r308 = load %ptr, %ptr* %t5
	%r309 = inttoptr %word 1 to %ptr
	%r310 = load %ptr, %ptr* %t9
	%r314 = bitcast %ptr %r310 to [0 x %ptr]*
	%r313 = ptrtoint %ptr %r309 to %word
	%r312 = getelementptr [0 x %ptr], [0 x %ptr]* %r314, %word 0, %word %r313
	store %ptr %r308, %ptr* %r312
	%r311 = bitcast %ptr %r308 to %ptr
	store %ptr %r311, %ptr* %t8
	br label %L1321
L1320:
	%r315 = load %ptr, %ptr* %t7
	%r316 = getelementptr [3 x i8], [3 x i8]* @str1327, %word 0, %word 0
	%r318 = call i32 @strcmp(%ptr %r315, %ptr %r316)
	%r319 = inttoptr %word %r318 to %ptr
	%r323 = ptrtoint %ptr %r319 to %word
	%r322 = icmp eq %word %r323, 0
	%r321 = zext i1 %r322 to %word
	%r320 = inttoptr %word %r321 to %ptr
	%r325 = ptrtoint %ptr %r320 to %word
	%r324 = icmp ne %word %r325, 0
	br i1 %r324, label %L1324, label %L1325
L1324:
	%r326 = load %ptr, %ptr* @"*arg/optimised*"
	%r327 = inttoptr %word 1 to %ptr
	%r331 = ptrtoint %ptr %r327 to %word
	%r330 = ptrtoint %ptr %r326 to %word
	%r329 = add %word %r331, %r330
	%r328 = inttoptr %word %r329 to %ptr
	store %ptr %r328, %ptr* @"*arg/optimised*"
	%r332 = inttoptr %word 1 to %ptr
	%r333 = inttoptr %word 1 to %ptr
	%r334 = load %ptr, %ptr* @"*arg/optimised*"
	%r338 = ptrtoint %ptr %r334 to %word
	%r337 = ptrtoint %ptr %r333 to %word
	%r336 = shl %word %r338, %r337
	%r335 = inttoptr %word %r336 to %ptr
	%r342 = ptrtoint %ptr %r335 to %word
	%r341 = ptrtoint %ptr %r332 to %word
	%r340 = add %word %r342, %r341
	%r339 = inttoptr %word %r340 to %ptr
	store %ptr %r339, %ptr* %t5
	%r343 = load %ptr, %ptr* @"*module*"
	store %ptr %r343, %ptr* %t10
	%r344 = inttoptr %word 0 to %ptr
	%r345 = inttoptr %word 1 to %ptr
	%r346 = load %ptr, %ptr* %t10
	%r350 = bitcast %ptr %r346 to [0 x %ptr]*
	%r349 = ptrtoint %ptr %r345 to %word
	%r348 = getelementptr [0 x %ptr], [0 x %ptr]* %r350, %word 0, %word %r349
	%r347 = load %ptr, %ptr* %r348
	store %ptr %r347, %ptr* %t10
	%r351 = inttoptr %word 0 to %ptr
	%r352 = inttoptr %word 1 to %ptr
	%r353 = load %ptr, %ptr* %t10
	%r357 = bitcast %ptr %r353 to [0 x %ptr]*
	%r356 = ptrtoint %ptr %r352 to %word
	%r355 = getelementptr [0 x %ptr], [0 x %ptr]* %r357, %word 0, %word %r356
	%r354 = load %ptr, %ptr* %r355
	%r358 = getelementptr [12 x i8], [12 x i8]* @str1328, %word 0, %word 0
	%r360 = call %ptr @intern(%ptr %r358)
	%r361 = call %ptr @"k/env/lookup-variable"(%ptr %r354, %ptr %r360)
	store %ptr %r361, %ptr* %t10
	%r362 = inttoptr %word 0 to %ptr
	%r363 = load %ptr, %ptr* %t5
	%r364 = inttoptr %word 1 to %ptr
	%r365 = load %ptr, %ptr* %t10
	%r369 = bitcast %ptr %r365 to [0 x %ptr]*
	%r368 = ptrtoint %ptr %r364 to %word
	%r367 = getelementptr [0 x %ptr], [0 x %ptr]* %r369, %word 0, %word %r368
	store %ptr %r363, %ptr* %r367
	%r366 = bitcast %ptr %r363 to %ptr
	store %ptr %r366, %ptr* %t9
	br label %L1326
L1325:
	%r370 = load %ptr, %ptr* %t7
	%r371 = getelementptr [2 x i8], [2 x i8]* @str1332, %word 0, %word 0
	%r373 = call i32 @strcmp(%ptr %r370, %ptr %r371)
	%r374 = inttoptr %word %r373 to %ptr
	%r378 = ptrtoint %ptr %r374 to %word
	%r377 = icmp eq %word %r378, 0
	%r376 = zext i1 %r377 to %word
	%r375 = inttoptr %word %r376 to %ptr
	%r380 = ptrtoint %ptr %r375 to %word
	%r379 = icmp ne %word %r380, 0
	br i1 %r379, label %L1329, label %L1330
L1329:
	%r381 = load %ptr, %ptr* @"libc/stdin"
	%r382 = call %ptr @"k/repl-stream"(%ptr %r381)
	store %ptr %r382, %ptr* %t10
	br label %L1331
L1330:
	%r383 = load %ptr, %ptr* %t7
	%r384 = getelementptr [7 x i8], [7 x i8]* @str1336, %word 0, %word 0
	%r386 = call i32 @strcmp(%ptr %r383, %ptr %r384)
	%r387 = inttoptr %word %r386 to %ptr
	%r391 = ptrtoint %ptr %r387 to %word
	%r390 = icmp eq %word %r391, 0
	%r389 = zext i1 %r390 to %word
	%r388 = inttoptr %word %r389 to %ptr
	%r393 = ptrtoint %ptr %r388 to %word
	%r392 = icmp ne %word %r393, 0
	br i1 %r392, label %L1333, label %L1334
L1333:
	%r394 = inttoptr %word 0 to %ptr
	store %ptr %r394, %ptr* %t12
	%r395 = load %ptr, %ptr* %t4
	%r396 = call %ptr @"get/type"(%ptr %r395)
	%r397 = inttoptr %word 19 to %ptr
	%r401 = ptrtoint %ptr %r397 to %word
	%r400 = ptrtoint %ptr %r396 to %word
	%r399 = icmp eq %word %r401, %r400
	%r398 = inttoptr i1 %r399 to %ptr
	store %ptr %r398, %ptr* %t12
	%r402 = inttoptr %word 0 to %ptr
	%r406 = ptrtoint %ptr %r402 to %word
	%r405 = ptrtoint %ptr %r398 to %word
	%r404 = icmp eq %word %r406, %r405
	%r403 = inttoptr i1 %r404 to %ptr
	%r408 = ptrtoint %ptr %r403 to %word
	%r407 = icmp ne %word %r408, 0
	br i1 %r407, label %L1338, label %L1337
L1338:
	%r409 = getelementptr [28 x i8], [28 x i8]* @str1339, %word 0, %word 0
	%r411 = call %ptr @fatal(%ptr %r409)
	store %ptr %r411, %ptr* %t12
	%r412 = inttoptr %word 0 to %ptr
	%r416 = ptrtoint %ptr %r412 to %word
	%r415 = ptrtoint %ptr %r411 to %word
	%r414 = icmp eq %word %r416, %r415
	%r413 = inttoptr i1 %r414 to %ptr
	%r418 = ptrtoint %ptr %r413 to %word
	%r417 = icmp ne %word %r418, 0
	br i1 %r417, label %L1340, label %L1337
L1340:
	br label %L1337
L1337:
	%r419 = load %ptr, %ptr* %t12
	%r420 = inttoptr %word 0 to %ptr
	%r421 = load %ptr, %ptr* %t4
	%r425 = bitcast %ptr %r421 to [0 x %ptr]*
	%r424 = ptrtoint %ptr %r420 to %word
	%r423 = getelementptr [0 x %ptr], [0 x %ptr]* %r425, %word 0, %word %r424
	%r422 = load %ptr, %ptr* %r423
	store %ptr %r422, %ptr* %t6
	%r426 = load %ptr, %ptr* %t6
	store %ptr %r426, %ptr* %t12
	%r427 = inttoptr %word 0 to %ptr
	%r428 = inttoptr %word 1 to %ptr
	%r429 = load %ptr, %ptr* %t12
	%r433 = bitcast %ptr %r429 to [0 x %ptr]*
	%r432 = ptrtoint %ptr %r428 to %word
	%r431 = getelementptr [0 x %ptr], [0 x %ptr]* %r433, %word 0, %word %r432
	%r430 = load %ptr, %ptr* %r431
	store %ptr %r430, %ptr* %t7
	%r434 = load %ptr, %ptr* %t3
	store %ptr %r434, %ptr* %t12
	%r435 = inttoptr %word 0 to %ptr
	%r436 = inttoptr %word 1 to %ptr
	%r437 = load %ptr, %ptr* %t4
	%r441 = bitcast %ptr %r437 to [0 x %ptr]*
	%r440 = ptrtoint %ptr %r436 to %word
	%r439 = getelementptr [0 x %ptr], [0 x %ptr]* %r441, %word 0, %word %r440
	%r438 = load %ptr, %ptr* %r439
	store %ptr %r438, %ptr* %t4
	%r442 = inttoptr %word 1 to %ptr
	%r443 = load %ptr, %ptr* %t12
	%r447 = bitcast %ptr %r443 to [0 x %ptr]*
	%r446 = ptrtoint %ptr %r442 to %word
	%r445 = getelementptr [0 x %ptr], [0 x %ptr]* %r447, %word 0, %word %r446
	store %ptr %r438, %ptr* %r445
	%r444 = bitcast %ptr %r438 to %ptr
	%r448 = load %ptr, %ptr* %t7
	%r449 = call %ptr @intern(%ptr %r448)
	store %ptr %r449, %ptr* %t12
	%r450 = load %ptr, %ptr* %t12
	%r451 = inttoptr %word 0 to %ptr
	%r452 = call %ptr @"new-<pair>"(%ptr %r450, %ptr %r451)
	store %ptr %r452, %ptr* %t13
	%r454 = getelementptr %ptr, %ptr* %t13, %word 0
	%r453 = bitcast %ptr* %r454 to %ptr
	%r455 = call %ptr @"gc/push-root"(%ptr %r453)
	%r456 = load %ptr, %ptr* %t13
	%r457 = load %ptr, %ptr* @"*module*"
	store %ptr %r457, %ptr* %t14
	%r458 = inttoptr %word 0 to %ptr
	%r459 = inttoptr %word 1 to %ptr
	%r460 = load %ptr, %ptr* %t14
	%r464 = bitcast %ptr %r460 to [0 x %ptr]*
	%r463 = ptrtoint %ptr %r459 to %word
	%r462 = getelementptr [0 x %ptr], [0 x %ptr]* %r464, %word 0, %word %r463
	%r461 = load %ptr, %ptr* %r462
	store %ptr %r461, %ptr* %t14
	%r465 = inttoptr %word 0 to %ptr
	%r466 = inttoptr %word 1 to %ptr
	%r467 = load %ptr, %ptr* %t14
	%r471 = bitcast %ptr %r467 to [0 x %ptr]*
	%r470 = ptrtoint %ptr %r466 to %word
	%r469 = getelementptr [0 x %ptr], [0 x %ptr]* %r471, %word 0, %word %r470
	%r468 = load %ptr, %ptr* %r469
	%r472 = call %ptr @"k/expand-encode-eval"(%ptr %r456, %ptr %r468)
	store %ptr %r472, %ptr* %t14
	%r474 = getelementptr %ptr, %ptr* %t13, %word 0
	%r473 = bitcast %ptr* %r474 to %ptr
	%r475 = call %ptr @"gc/pop-root"(%ptr %r473)
	%r476 = load %ptr, %ptr* %t14
	store %ptr %r476, %ptr* %t11
	br label %L1335
L1334:
	%r477 = load %ptr, %ptr* %t7
	%r478 = getelementptr [9 x i8], [9 x i8]* @str1344, %word 0, %word 0
	%r480 = call i32 @strcmp(%ptr %r477, %ptr %r478)
	%r481 = inttoptr %word %r480 to %ptr
	%r485 = ptrtoint %ptr %r481 to %word
	%r484 = icmp eq %word %r485, 0
	%r483 = zext i1 %r484 to %word
	%r482 = inttoptr %word %r483 to %ptr
	%r487 = ptrtoint %ptr %r482 to %word
	%r486 = icmp ne %word %r487, 0
	br i1 %r486, label %L1341, label %L1342
L1341:
	%r488 = inttoptr %word 0 to %ptr
	store %ptr %r488, %ptr* %t13
	%r489 = inttoptr %word 1 to %ptr
	store %ptr %r489, %ptr* %t14
	%r490 = load %ptr, %ptr* %t4
	%r491 = call %ptr @"get/type"(%ptr %r490)
	%r492 = inttoptr %word 19 to %ptr
	%r496 = ptrtoint %ptr %r492 to %word
	%r495 = ptrtoint %ptr %r491 to %word
	%r494 = icmp eq %word %r496, %r495
	%r493 = inttoptr i1 %r494 to %ptr
	store %ptr %r493, %ptr* %t14
	%r497 = inttoptr %word 0 to %ptr
	%r501 = ptrtoint %ptr %r497 to %word
	%r500 = ptrtoint %ptr %r493 to %word
	%r499 = icmp eq %word %r501, %r500
	%r498 = inttoptr i1 %r499 to %ptr
	%r503 = ptrtoint %ptr %r498 to %word
	%r502 = icmp ne %word %r503, 0
	br i1 %r502, label %L1346, label %L1347
L1347:
	%r504 = inttoptr %word 1 to %ptr
	%r505 = load %ptr, %ptr* %t4
	%r509 = bitcast %ptr %r505 to [0 x %ptr]*
	%r508 = ptrtoint %ptr %r504 to %word
	%r507 = getelementptr [0 x %ptr], [0 x %ptr]* %r509, %word 0, %word %r508
	%r506 = load %ptr, %ptr* %r507
	%r510 = call %ptr @"get/type"(%ptr %r506)
	%r511 = inttoptr %word 19 to %ptr
	%r515 = ptrtoint %ptr %r511 to %word
	%r514 = ptrtoint %ptr %r510 to %word
	%r513 = icmp eq %word %r515, %r514
	%r512 = inttoptr i1 %r513 to %ptr
	store %ptr %r512, %ptr* %t14
	%r516 = inttoptr %word 0 to %ptr
	%r520 = ptrtoint %ptr %r516 to %word
	%r519 = ptrtoint %ptr %r512 to %word
	%r518 = icmp eq %word %r520, %r519
	%r517 = inttoptr i1 %r518 to %ptr
	%r522 = ptrtoint %ptr %r517 to %word
	%r521 = icmp ne %word %r522, 0
	br i1 %r521, label %L1346, label %L1348
L1348:
	br label %L1346
L1346:
	%r523 = load %ptr, %ptr* %t14
	store %ptr %r523, %ptr* %t13
	%r524 = inttoptr %word 0 to %ptr
	%r528 = ptrtoint %ptr %r524 to %word
	%r527 = ptrtoint %ptr %r523 to %word
	%r526 = icmp eq %word %r528, %r527
	%r525 = inttoptr i1 %r526 to %ptr
	%r530 = ptrtoint %ptr %r525 to %word
	%r529 = icmp ne %word %r530, 0
	br i1 %r529, label %L1349, label %L1345
L1349:
	%r531 = getelementptr [32 x i8], [32 x i8]* @str1350, %word 0, %word 0
	%r533 = call %ptr @fatal(%ptr %r531)
	store %ptr %r533, %ptr* %t13
	%r534 = inttoptr %word 0 to %ptr
	%r538 = ptrtoint %ptr %r534 to %word
	%r537 = ptrtoint %ptr %r533 to %word
	%r536 = icmp eq %word %r538, %r537
	%r535 = inttoptr i1 %r536 to %ptr
	%r540 = ptrtoint %ptr %r535 to %word
	%r539 = icmp ne %word %r540, 0
	br i1 %r539, label %L1351, label %L1345
L1351:
	br label %L1345
L1345:
	%r541 = load %ptr, %ptr* %t13
	%r542 = load %ptr, %ptr* %t4
	%r543 = call %ptr @"k/car"(%ptr %r542)
	store %ptr %r543, %ptr* %t13
	%r544 = load %ptr, %ptr* %t4
	%r545 = call %ptr @"k/cadr"(%ptr %r544)
	store %ptr %r545, %ptr* %t14
	%r546 = load %ptr, %ptr* %t3
	store %ptr %r546, %ptr* %t15
	%r547 = inttoptr %word 0 to %ptr
	%r548 = inttoptr %word 1 to %ptr
	%r549 = inttoptr %word 1 to %ptr
	%r550 = load %ptr, %ptr* %t4
	%r554 = bitcast %ptr %r550 to [0 x %ptr]*
	%r553 = ptrtoint %ptr %r549 to %word
	%r552 = getelementptr [0 x %ptr], [0 x %ptr]* %r554, %word 0, %word %r553
	%r551 = load %ptr, %ptr* %r552
	%r558 = bitcast %ptr %r551 to [0 x %ptr]*
	%r557 = ptrtoint %ptr %r548 to %word
	%r556 = getelementptr [0 x %ptr], [0 x %ptr]* %r558, %word 0, %word %r557
	%r555 = load %ptr, %ptr* %r556
	store %ptr %r555, %ptr* %t4
	%r559 = inttoptr %word 1 to %ptr
	%r560 = load %ptr, %ptr* %t15
	%r564 = bitcast %ptr %r560 to [0 x %ptr]*
	%r563 = ptrtoint %ptr %r559 to %word
	%r562 = getelementptr [0 x %ptr], [0 x %ptr]* %r564, %word 0, %word %r563
	store %ptr %r555, %ptr* %r562
	%r561 = bitcast %ptr %r555 to %ptr
	%r565 = load %ptr, %ptr* %t14
	store %ptr %r565, %ptr* %t15
	%r566 = inttoptr %word 0 to %ptr
	%r567 = inttoptr %word 1 to %ptr
	%r568 = load %ptr, %ptr* %t15
	%r572 = bitcast %ptr %r568 to [0 x %ptr]*
	%r571 = ptrtoint %ptr %r567 to %word
	%r570 = getelementptr [0 x %ptr], [0 x %ptr]* %r572, %word 0, %word %r571
	%r569 = load %ptr, %ptr* %r570
	store %ptr %r569, %ptr* %t15
	%r573 = load %ptr, %ptr* %t15
	store %ptr %r573, %ptr* %t16
	%r574 = load %ptr, %ptr* %t15
	%r576 = getelementptr %ptr, %ptr* %t16, %word 0
	%r575 = bitcast %ptr* %r576 to %ptr
	%r577 = inttoptr %word 0 to %ptr
	%ffi-cast578 = ptrtoint %ptr %r577 to i32
	%r579 = call i32 @strtoul(%ptr %r574, %ptr %r575, i32 %ffi-cast578)
	%r580 = inttoptr %word %r579 to %ptr
	store %ptr %r580, %ptr* %t17
	%r581 = inttoptr %word 1 to %ptr
	store %ptr %r581, %ptr* %t18
	%r582 = inttoptr %word 0 to %ptr
	%r583 = load %ptr, %ptr* %t16
	%r588 = bitcast %ptr %r583 to [0 x i8]*
	%r587 = ptrtoint %ptr %r582 to %word
	%r586 = getelementptr [0 x i8], [0 x i8]* %r588, %word 0, %word %r587
	%r585 = load i8, i8* %r586
	%r584 = inttoptr i8 %r585 to %ptr
	%r589 = inttoptr %word 0 to %ptr
	%r593 = ptrtoint %ptr %r589 to %word
	%r592 = ptrtoint %ptr %r584 to %word
	%r591 = icmp eq %word %r593, %r592
	%r590 = inttoptr i1 %r591 to %ptr
	store %ptr %r590, %ptr* %t18
	%r594 = inttoptr %word 0 to %ptr
	%r598 = ptrtoint %ptr %r594 to %word
	%r597 = ptrtoint %ptr %r590 to %word
	%r596 = icmp eq %word %r598, %r597
	%r595 = inttoptr i1 %r596 to %ptr
	%r600 = ptrtoint %ptr %r595 to %word
	%r599 = icmp ne %word %r600, 0
	br i1 %r599, label %L1352, label %L1353
L1353:
	%r601 = inttoptr %word 1 to %ptr
	%r602 = inttoptr %word 1 to %ptr
	%r603 = load %ptr, %ptr* %t17
	%r607 = ptrtoint %ptr %r603 to %word
	%r606 = ptrtoint %ptr %r602 to %word
	%r605 = shl %word %r607, %r606
	%r604 = inttoptr %word %r605 to %ptr
	%r611 = ptrtoint %ptr %r604 to %word
	%r610 = ptrtoint %ptr %r601 to %word
	%r609 = add %word %r611, %r610
	%r608 = inttoptr %word %r609 to %ptr
	store %ptr %r608, %ptr* %t14
	store %ptr %r608, %ptr* %t18
	%r612 = inttoptr %word 0 to %ptr
	%r616 = ptrtoint %ptr %r612 to %word
	%r615 = ptrtoint %ptr %r608 to %word
	%r614 = icmp eq %word %r616, %r615
	%r613 = inttoptr i1 %r614 to %ptr
	%r618 = ptrtoint %ptr %r613 to %word
	%r617 = icmp ne %word %r618, 0
	br i1 %r617, label %L1352, label %L1354
L1354:
	br label %L1352
L1352:
	%r619 = load %ptr, %ptr* %t18
	%r620 = load %ptr, %ptr* %t14
	%r621 = inttoptr %word 0 to %ptr
	%r622 = call %ptr @"new-<pair>"(%ptr %r620, %ptr %r621)
	store %ptr %r622, %ptr* %t15
	%r624 = getelementptr %ptr, %ptr* %t15, %word 0
	%r623 = bitcast %ptr* %r624 to %ptr
	%r625 = call %ptr @"gc/push-root"(%ptr %r623)
	%r626 = load %ptr, %ptr* %t13
	store %ptr %r626, %ptr* %t16
	%r627 = inttoptr %word 0 to %ptr
	%r628 = inttoptr %word 1 to %ptr
	%r629 = load %ptr, %ptr* %t16
	%r633 = bitcast %ptr %r629 to [0 x %ptr]*
	%r632 = ptrtoint %ptr %r628 to %word
	%r631 = getelementptr [0 x %ptr], [0 x %ptr]* %r633, %word 0, %word %r632
	%r630 = load %ptr, %ptr* %r631
	%r634 = call %ptr @intern(%ptr %r630)
	%r635 = load %ptr, %ptr* %t15
	%r636 = call %ptr @"new-<pair>"(%ptr %r634, %ptr %r635)
	store %ptr %r636, %ptr* %t15
	%r637 = load %ptr, %ptr* @"symbol/define"
	%r638 = load %ptr, %ptr* %t15
	%r639 = call %ptr @"new-<pair>"(%ptr %r637, %ptr %r638)
	store %ptr %r639, %ptr* %t15
	%r640 = load %ptr, %ptr* %t15
	%r641 = load %ptr, %ptr* @"*module*"
	store %ptr %r641, %ptr* %t16
	%r642 = inttoptr %word 0 to %ptr
	%r643 = inttoptr %word 1 to %ptr
	%r644 = load %ptr, %ptr* %t16
	%r648 = bitcast %ptr %r644 to [0 x %ptr]*
	%r647 = ptrtoint %ptr %r643 to %word
	%r646 = getelementptr [0 x %ptr], [0 x %ptr]* %r648, %word 0, %word %r647
	%r645 = load %ptr, %ptr* %r646
	store %ptr %r645, %ptr* %t16
	%r649 = inttoptr %word 0 to %ptr
	%r650 = inttoptr %word 1 to %ptr
	%r651 = load %ptr, %ptr* %t16
	%r655 = bitcast %ptr %r651 to [0 x %ptr]*
	%r654 = ptrtoint %ptr %r650 to %word
	%r653 = getelementptr [0 x %ptr], [0 x %ptr]* %r655, %word 0, %word %r654
	%r652 = load %ptr, %ptr* %r653
	%r656 = call %ptr @"k/expand-encode-eval"(%ptr %r640, %ptr %r652)
	store %ptr %r656, %ptr* %t16
	%r658 = getelementptr %ptr, %ptr* %t15, %word 0
	%r657 = bitcast %ptr* %r658 to %ptr
	%r659 = call %ptr @"gc/pop-root"(%ptr %r657)
	%r660 = load %ptr, %ptr* %t16
	store %ptr %r660, %ptr* %t12
	br label %L1343
L1342:
	%r661 = load %ptr, %ptr* %t7
	%r662 = getelementptr [2 x i8], [2 x i8]* @str1355, %word 0, %word 0
	%r664 = call %ptr @fopen(%ptr %r661, %ptr %r662)
	store %ptr %r664, %ptr* %t14
	%r665 = inttoptr %word 0 to %ptr
	store %ptr %r665, %ptr* %t13
	%r666 = load %ptr, %ptr* %t14
	store %ptr %r666, %ptr* %t13
	%r667 = inttoptr %word 0 to %ptr
	%r671 = ptrtoint %ptr %r667 to %word
	%r670 = ptrtoint %ptr %r666 to %word
	%r669 = icmp eq %word %r671, %r670
	%r668 = inttoptr i1 %r669 to %ptr
	%r673 = ptrtoint %ptr %r668 to %word
	%r672 = icmp ne %word %r673, 0
	br i1 %r672, label %L1357, label %L1356
L1357:
	%r674 = getelementptr [17 x i8], [17 x i8]* @str1358, %word 0, %word 0
	%r676 = load %ptr, %ptr* %t7
	%r677 = call %ptr @fatal1(%ptr %r674, %ptr %r676)
	store %ptr %r677, %ptr* %t13
	%r678 = inttoptr %word 0 to %ptr
	%r682 = ptrtoint %ptr %r678 to %word
	%r681 = ptrtoint %ptr %r677 to %word
	%r680 = icmp eq %word %r682, %r681
	%r679 = inttoptr i1 %r680 to %ptr
	%r684 = ptrtoint %ptr %r679 to %word
	%r683 = icmp ne %word %r684, 0
	br i1 %r683, label %L1359, label %L1356
L1359:
	br label %L1356
L1356:
	%r685 = load %ptr, %ptr* %t13
	%r686 = load %ptr, %ptr* %t14
	%r687 = call %ptr @"k/repl-stream"(%ptr %r686)
	%r688 = load %ptr, %ptr* %t14
	%r689 = call i32 @fclose(%ptr %r688)
	%r690 = inttoptr %word %r689 to %ptr
	store %ptr %r690, %ptr* %t12
	br label %L1343
L1343:
	%r691 = load %ptr, %ptr* %t12
	store %ptr %r691, %ptr* %t11
	br label %L1335
L1335:
	%r692 = load %ptr, %ptr* %t11
	store %ptr %r692, %ptr* %t10
	br label %L1331
L1331:
	%r693 = load %ptr, %ptr* %t10
	store %ptr %r693, %ptr* %t9
	br label %L1326
L1326:
	%r694 = load %ptr, %ptr* %t9
	store %ptr %r694, %ptr* %t8
	br label %L1321
L1321:
	%r695 = load %ptr, %ptr* %t8
	store %ptr %r695, %ptr* %t8
	%r697 = getelementptr %ptr, %ptr* %t5, %word 0
	%r696 = bitcast %ptr* %r697 to %ptr
	%r698 = call %ptr @"gc/pop-root"(%ptr %r696)
	%r700 = getelementptr %ptr, %ptr* %t6, %word 0
	%r699 = bitcast %ptr* %r700 to %ptr
	%r701 = call %ptr @"gc/pop-root"(%ptr %r699)
	%r702 = load %ptr, %ptr* %t8
	br label %L1317
L1317:
	%r703 = load %ptr, %ptr* %t3
	store %ptr %r703, %ptr* %t7
	%r704 = inttoptr %word 0 to %ptr
	%r705 = inttoptr %word 1 to %ptr
	%r706 = load %ptr, %ptr* %t7
	%r710 = bitcast %ptr %r706 to [0 x %ptr]*
	%r709 = ptrtoint %ptr %r705 to %word
	%r708 = getelementptr [0 x %ptr], [0 x %ptr]* %r710, %word 0, %word %r709
	%r707 = load %ptr, %ptr* %r708
	store %ptr %r707, %ptr* %t4
	%r711 = call %ptr @"get/type"(%ptr %r707)
	%r712 = inttoptr %word 19 to %ptr
	%r716 = ptrtoint %ptr %r712 to %word
	%r715 = ptrtoint %ptr %r711 to %word
	%r714 = icmp eq %word %r716, %r715
	%r713 = inttoptr i1 %r714 to %ptr
	%r718 = ptrtoint %ptr %r713 to %word
	%r717 = icmp ne %word %r718, 0
	br i1 %r717, label %L1316, label %L1318
L1318:
	%r719 = call %ptr @"libc/flush-streams"()
	%r720 = inttoptr %word 1 to %ptr
	store %ptr %r720, %ptr* %t3
	%r721 = load %ptr, %ptr* @"*arg/verbose*"
	%r722 = inttoptr %word 0 to %ptr
	%r726 = ptrtoint %ptr %r722 to %word
	%r725 = ptrtoint %ptr %r721 to %word
	%r724 = icmp slt %word %r726, %r725
	%r723 = inttoptr i1 %r724 to %ptr
	store %ptr %r723, %ptr* %t3
	%r727 = inttoptr %word 0 to %ptr
	%r731 = ptrtoint %ptr %r727 to %word
	%r730 = ptrtoint %ptr %r723 to %word
	%r729 = icmp eq %word %r731, %r730
	%r728 = inttoptr i1 %r729 to %ptr
	%r733 = ptrtoint %ptr %r728 to %word
	%r732 = icmp ne %word %r733, 0
	br i1 %r732, label %L1360, label %L1361
L1361:
	%r734 = call %ptr @"gc/collect"()
	%r735 = getelementptr [37 x i8], [37 x i8]* @str1362, %word 0, %word 0
	%r737 = load %ptr, %ptr* @"gc/objects-live"
	%r738 = load %ptr, %ptr* @"gc/bytes-used"
	%r739 = load %ptr, %ptr* @"gc/bytes-free"
	%r740 = call i32 (%ptr, ...) @printf(%ptr %r735, %ptr %r737, %ptr %r738, %ptr %r739)
	%r741 = inttoptr %word %r740 to %ptr
	store %ptr %r741, %ptr* %t3
	%r742 = inttoptr %word 0 to %ptr
	%r746 = ptrtoint %ptr %r742 to %word
	%r745 = ptrtoint %ptr %r741 to %word
	%r744 = icmp eq %word %r746, %r745
	%r743 = inttoptr i1 %r744 to %ptr
	%r748 = ptrtoint %ptr %r743 to %word
	%r747 = icmp ne %word %r748, 0
	br i1 %r747, label %L1360, label %L1363
L1363:
	br label %L1360
L1360:
	%r749 = load %ptr, %ptr* %t3
	%r750 = load %ptr, %ptr* @"libc/stderr"
	%r751 = getelementptr [33 x i8], [33 x i8]* @str1364, %word 0, %word 0
	%r753 = load %ptr, %ptr* @"gc/objects-live"
	%r754 = load %ptr, %ptr* @"gc/bytes-used"
	%r755 = load %ptr, %ptr* @"gc/bytes-free"
	%r756 = call i32 (%ptr, %ptr, ...) @fprintf(%ptr %r750, %ptr %r751, %ptr %r753, %ptr %r754, %ptr %r755)
	%r757 = inttoptr %word %r756 to %ptr
	%r758 = call %ptr @"libc/flush-streams"()
	%r759 = inttoptr %word 0 to %ptr
	ret %ptr %r759
}
@"k/+done+" = global %ptr inttoptr (%word 0 to %ptr)
@"*backtrace-stack*" = global %ptr inttoptr (%word 0 to %ptr)
@"*backtrace-index*" = global %ptr inttoptr (%word 0 to %ptr)
@"libc/stdin" = global %ptr inttoptr (%word 0 to %ptr)
@"libc/stdout" = global %ptr inttoptr (%word 0 to %ptr)
@"libc/stderr" = global %ptr inttoptr (%word 0 to %ptr)
; form libc/EOF
; form k/error
; form %level-shift-types
; form k/<undefined>
; form k/<target-vm-pointer>
; form k/<data>
; form k/<long>
; form k/<string>
; form k/<symbol>
; form k/<pair>
; form k/<array>
; form k/<expr>
; form k/<form>
; form k/<fixed>
; form k/<subr>
; form k/<variable>
; form k/<env>
; form k/<context>
; form k/<module>
; form %get/type
; form is
; form get
; form put
; form get/globals
; form get/globals*
; form is/long
; form is/pair
; form get/long
; form get/head
; form put/head
; form get/tail
; form put/tail
; form is/tptr
; form get/tptr
; form get/string
; form get/symbol
; form get/variable-value
; form put/variable-value
@"gc/quantum" = global %ptr inttoptr (%word 51200 to %ptr)
@"gc/frequency" = global %ptr inttoptr (%word 32768 to %ptr)
@"gc/objects-live" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/bytes-used" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/bytes-free" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/roots" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/root-count" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/root-max" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/memory-base" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/memory-last" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/alloc-count" = global %ptr inttoptr (%word 0 to %ptr)
@"gc/collection-count" = global %ptr inttoptr (%word 0 to %ptr)
; form gc/protect
; form gc/let*
; form new-object
; form new-object/opaque
; form new-record-instance
; form new-record-instance/opaque
; form %new-<long>
; form new-<long>
@"*arg/verbose*" = global %ptr inttoptr (%word 0 to %ptr)
@"*arg/optimised*" = global %ptr inttoptr (%word 0 to %ptr)
@"*module*" = global %ptr inttoptr (%word 0 to %ptr)
@"var/*expanders*" = global %ptr inttoptr (%word 0 to %ptr)
@"var/*encoders*" = global %ptr inttoptr (%word 0 to %ptr)
@"var/*evaluators*" = global %ptr inttoptr (%word 0 to %ptr)
@"var/*applicators*" = global %ptr inttoptr (%word 0 to %ptr)
@"var/*input*" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/t" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/dot" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/define" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/set" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/quote" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/quasiquote" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/unquote" = global %ptr inttoptr (%word 0 to %ptr)
@"symbol/unquote_splicing" = global %ptr inttoptr (%word 0 to %ptr)
@"fixed-subr/quote" = global %ptr inttoptr (%word 0 to %ptr)
@"fixed-subr/lambda" = global %ptr inttoptr (%word 0 to %ptr)
@"fixed-subr/let" = global %ptr inttoptr (%word 0 to %ptr)
@"fixed-subr/define" = global %ptr inttoptr (%word 0 to %ptr)
@"fixed-subr/set" = global %ptr inttoptr (%word 0 to %ptr)
; form define-subr
; form define-binary
; form define-relation
; form instantiate-subrs
; form %stdio-init
