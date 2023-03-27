# 支持 make all, make run, make build_so, make run_by_so, make clean
# 需要的环境变量已经�?makefile 中临时自动导入全局
cc           := g++
# 生成的可执行文件的名�?./workspace/pro
name         := pro
workdir      := workspace
srcdir       := src
# export CUDA_VISIBLE_DEVICES=0
# 存放编译产生的临�?.o 文件�?make clean会自动消�?
objdir       := objs
stdcpp       := c++11
dst_so_path  := libs/alg/libEzviewImageStructure.so
project_name := EzviewImageStructure
# 要执�?demo.cpp 或�?demo_thread.cpp , 在这里更�?
demodir		 := demo
# 存放宏定�?#debug �?  DEBUG_OBJECT  DEBUG_ROI
defined      := ARCH_X86_64_LINUX
pwd          := $(abspath .)
# 运行输入的参�?
run_args     := cpu new_visual
# 暂未使用
nvcc         := nvcc
cuda_arch    := 

# 导出你的环境变量值，可以在程序中使用，该功能还可以写成例如：
# export LD_LIBRARY_PATH=xxxxx，作用与你在终端中设置是一样的
export pwd workdir srcdir objdir demodir

demo_srcs   := $(shell find $(demodir) -name "*.cpp")
demo_objs   := $(demo_srcs:.cpp=.o)
demo_objs   := $(demo_objs:$(demodir)/%=$(objdir)/%)

cpp_srcs := $(shell find $(srcdir) -name "*.cpp")
cpp_objs := $(cpp_srcs:.cpp=.o)
cpp_objs := $(cpp_objs:$(srcdir)/%=$(objdir)/%)

cc_srcs := $(shell find $(srcdir) -name "*.cc")
cc_objs := $(cc_srcs:.cc=.o)
cc_objs := $(cc_objs:$(srcdir)/%=$(objdir)/%)

cu_srcs  := $(shell find src -name "*.cu")
cu_objs  := $(cu_srcs:.cu=.cu.o)
cu_objs  := $(cu_objs:src/%=objs/%)

lean_cuda     := /usr/local/cuda
lean_cida     := /usr/local/cida
lean_opencv   := /usr/local
lean_tensorRT := /usr/local/trt
lean_cudnn    := /usr/local/x86_64-linux-gnu

include_paths := include            \
   			$(lean_cuda)/include     \
			$(lean_cida)/include     \
			$(lean_tensorRT)/include \
			$(lean_opencv)/include/opencv4   \
			$(lean_cudnn)   \
			src	\
			../Common/CUDA110/include/ \
			demo

# 最后一个为 自己制造的so文件的路�?
library_paths :=  $(lean_cuda)/lib64 \
			$(lean_cida)/lib     \
			$(lean_tensorRT)/lib \
			$(lean_opencv)/lib   \
			$(lean_cudnn)	\
			$(pwd)/libs/alg/

# 把library path给拼接为一个字符串，例如a b c => a:b:c
# 然后使得LD_LIBRARY_PATH=a:b:c
empty := 
library_path_export := $(subst $(empty) $(empty),:,$(library_paths))

link_cida   := cida_single_infer-3.2.1.1
link_opencv := opencv_world
link_cuda   := cudart nppc nppicc nppisu nppial nppig  nppidei cuda cublas
link_trt    := myelin nvparsers nvonnxparser nvinfer nvinfer_plugin onnxruntime
link_sys    := m stdc++
link_cudnn  := cudnn
link_librarys := $(link_cida) $(link_opencv) $(link_cuda) $(link_trt) $(link_sys) $(link_cudnn)

run_paths     := $(foreach item,$(library_paths),-Wl,-rpath=$(item))
include_paths := $(foreach item,$(include_paths),-I$(item))
library_paths := $(foreach item,$(library_paths),-L$(item))
link_librarys := $(foreach item,$(link_librarys),-l$(item))
defined       := $(foreach item,$(defined),-D$(item))

link_librarys     += -pthread -fopenmp

cpp_compile_flags := -std=$(stdcpp) -fPIC -m64 -O0 -w -g  $(defined) -fvisibility=hidden
cpp_compile_flags += $(include_paths)
cu_compile_flags  := -std=c++11 -w -O0 -Xcompiler "$(cpp_compile_flags)" $(cuda_arch) $(support_define) --compiler-options
cu_compile_flags  += $(include_paths)

link_flags 		  += $(library_paths) $(link_librarys) $(run_paths)

#pro         workspace/pro
$(name)   : $(workdir)/$(name)
all       : $(name)

run       : $(name)
	@echo Run_start
	@./$(workdir)/$(name) $(run_args)

build_so : $(dst_so_path)
$(dst_so_path) : $(cpp_objs) $(cc_objs) $(cu_objs) 
	@echo Link $@
	@mkdir -p $(dir $@)
	@$(cc) $^ -shared -o $@ $(link_flags)

run_by_so : $(dst_so_path)
	@echo Compile demo.cpp
	@$(cc) -c $(demo_srcs)  -o objs/$(project_name).o $(cpp_compile_flags)
	@echo Link dst_so
	@$(cc) objs/$(project_name).o -o $(workdir)/$(name) -Llibs/alg -l$(project_name) $(link_flags)
	@./$(workdir)/$(name) $(run_args)

$(workdir)/$(name) : $(cpp_objs) $(cc_objs) $(cu_objs) $(demo_objs)
	@echo Link $@
	@mkdir -p $(dir $@)
	@$(cc) $^ -o $@ $(link_flags)

$(objdir)/%.o : $(srcdir)/%.cpp
	@echo Compile CXX $<
	@mkdir -p $(dir $@)
	@$(cc) -c $< -o $@ $(cpp_compile_flags)

$(objdir)/%.o : $(srcdir)/%.cc
	@echo Compile CUDA $<
	@mkdir -p $(dir $@)
	@$(cc) -c $< -o $@ $(cpp_compile_flags)

objs/%.cu.o : src/%.cu
	@echo Compile CUDA $<
	@mkdir -p $(dir $@)
	@$(nvcc) -c $< -o $@ $(cu_compile_flags)

$(objdir)/%.o : $(demodir)/%.cpp
	@echo Compile DEMO $<
	@mkdir -p $(dir $@)
	@$(cc) -c $< -o $@ $(cpp_compile_flags)

# 定义清理指令
clean :
	@rm -rf $(objdir) $(workdir)/$(name)
	@rm -f libs/alg/* ./*.o pro src/*.o demo/*.o workspace/core.* core.*

debug :
	@echo $(LD_LIBRARY_PATH):$(library_path_export)

# 防止符号被当做文�?
.PHONY : clean run $(name) all build_so run_by_so

# 导出依赖库路径，使得能够运行起来
export LD_LIBRARY_PATH:=$(LD_LIBRARY_PATH):$(library_path_export)
