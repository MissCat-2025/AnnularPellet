#!/bin/bash

# 自动修改Makefile和App.C文件添加RACCOON配置的脚本
# 使用方法: ./update_makefile_raccoon.sh

set -e  # 遇到错误就退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：修改Makefile
modify_makefile() {
    local MAKEFILE="Makefile"
    
    if [ ! -f "$MAKEFILE" ]; then
        print_error "当前目录下未找到Makefile文件！"
        return 1
    fi

    print_info "开始修改Makefile，添加RACCOON配置..."

    # 创建备份
    local BACKUP_FILE="Makefile.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$MAKEFILE" "$BACKUP_FILE"
    print_info "已创建Makefile备份文件: $BACKUP_FILE"

    # 检查是否已经包含RACCOON配置
    local SKIP_RACCOON_DIR=false
    local SKIP_RACCOON_DEP=false
    
    if grep -q "RACCOON_DIR" "$MAKEFILE"; then
        print_warning "Makefile中已经包含RACCOON_DIR配置，将跳过添加RACCOON目录设置"
        SKIP_RACCOON_DIR=true
    fi

    if grep -q "RACCOON.*:=.*yes" "$MAKEFILE"; then
        print_warning "Makefile中已经包含RACCOON依赖配置，将跳过添加RACCOON依赖"
        SKIP_RACCOON_DEP=true
    fi

    # 创建临时文件
    local TEMP_FILE=$(mktemp)

    # 处理Makefile
    local raccoon_dir_added=false
    local raccoon_dep_added=false

    while IFS= read -r line || [ -n "$line" ]; do
        echo "$line" >> "$TEMP_FILE"
        
        # 在"# MOOSE_DIR - Root directory of the MOOSE project"后添加RACCOON目录配置
        if echo "$line" | grep -q "# MOOSE_DIR.*Root directory.*MOOSE project" && [ "$SKIP_RACCOON_DIR" = false ]; then
            echo "# RACCOON_DIR      - Root directory of the RACCOON project" >> "$TEMP_FILE"
            echo "#" >> "$TEMP_FILE"
            echo "###############################################################################" >> "$TEMP_FILE"
            echo "" >> "$TEMP_FILE"
            echo "# Set the RACCOON directory" >> "$TEMP_FILE"
            echo "RACCOON_DIR        ?= \$(shell dirname \`pwd\`)/raccoon" >> "$TEMP_FILE"
            raccoon_dir_added=true
            print_info "已在MOOSE_DIR注释后添加RACCOON目录配置"
        fi
        
        # 在modules.mk后添加RACCOON依赖配置
        if echo "$line" | grep -q "include.*modules\.mk" && [ "$SKIP_RACCOON_DEP" = false ]; then
            echo "" >> "$TEMP_FILE"
            echo "################################## RACCOON ####################################" >> "$TEMP_FILE"
            echo "# Include RACCOON as a dependency" >> "$TEMP_FILE"
            echo "RACCOON            := yes" >> "$TEMP_FILE"
            echo "RACCOON_LIB        := yes" >> "$TEMP_FILE"
            echo "# 添加RACCOON的所有include路径" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include/materials/small_deformation_models" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include/materials/hardening_models" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include/interfaces" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include/materials" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include/kernels" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include/base" >> "$TEMP_FILE"
            echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include/utils" >> "$TEMP_FILE"



            echo "ADDITIONAL_LIBS     += -L\$(RACCOON_DIR)/lib -lraccoon-\$(METHOD)" >> "$TEMP_FILE"
            raccoon_dep_added=true
            print_info "已在modules.mk后添加RACCOON依赖配置"
        fi
        
    done < "$MAKEFILE"

    # 检查是否成功添加
    if [ "$SKIP_RACCOON_DIR" = false ] && [ "$raccoon_dir_added" = false ]; then
        print_warning "未找到'MOOSE_DIR - Root directory'注释行，在文件开头添加RACCOON目录配置..."
        
        # 在文件开头添加配置
        local TEMP_FILE2=$(mktemp)
        echo "# Set the RACCOON directory" > "$TEMP_FILE2"
        echo "RACCOON_DIR        ?= \$(shell dirname \`pwd\`)/raccoon" >> "$TEMP_FILE2"
        echo "" >> "$TEMP_FILE2"
        cat "$TEMP_FILE" >> "$TEMP_FILE2"
        mv "$TEMP_FILE2" "$TEMP_FILE"
        raccoon_dir_added=true
    fi

    if [ "$SKIP_RACCOON_DEP" = false ] && [ "$raccoon_dep_added" = false ]; then
        print_warning "未找到modules.mk include行，在文件末尾添加RACCOON依赖配置..."
        echo "" >> "$TEMP_FILE"
        echo "################################## RACCOON ####################################" >> "$TEMP_FILE"
        echo "# Include RACCOON as a dependency" >> "$TEMP_FILE"
        echo "RACCOON            := yes" >> "$TEMP_FILE"
        echo "RACCOON_LIB        := yes" >> "$TEMP_FILE"
        echo "ADDITIONAL_INCLUDES += -I\$(RACCOON_DIR)/include" >> "$TEMP_FILE"
        echo "ADDITIONAL_LIBS     += -L\$(RACCOON_DIR)/lib -lraccoon-\$(METHOD)" >> "$TEMP_FILE"
    fi

    # 替换原文件
    mv "$TEMP_FILE" "$MAKEFILE"
    print_success "Makefile修改完成！"
    
    return 0
}

# 函数：修改App.C文件
modify_app_file() {
    print_info "开始查找和修改App.C文件..."
    
    # 查找App.C文件
    local APP_FILE=""
    local APP_FILES=($(find src/base -name "*App.C" 2>/dev/null || true))
    
    if [ ${#APP_FILES[@]} -eq 0 ]; then
        print_error "未找到任何App.C文件！"
        print_info "查找路径: src/base/*App.C"
        return 1
    elif [ ${#APP_FILES[@]} -gt 1 ]; then
        print_warning "找到多个App.C文件:"
        for file in "${APP_FILES[@]}"; do
            echo "  - $file"
        done
        APP_FILE="${APP_FILES[0]}"
        print_info "将使用第一个文件: $APP_FILE"
    else
        APP_FILE="${APP_FILES[0]}"
        print_info "找到App.C文件: $APP_FILE"
    fi
    
    # 创建备份
    local BACKUP_FILE="${APP_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$APP_FILE" "$BACKUP_FILE"
    print_info "已创建App.C备份文件: $BACKUP_FILE"
    
    # 检查是否已经包含RACCOON配置
    local SKIP_INCLUDE=false
    local SKIP_REGISTER=false
    
    if grep -q "#include.*raccoonApp\.h" "$APP_FILE"; then
        print_warning "App.C中已经包含raccoonApp.h，将跳过添加include"
        SKIP_INCLUDE=true
    fi
    
    if grep -q "raccoonApp::registerAll" "$APP_FILE"; then
        print_warning "App.C中已经包含raccoonApp::registerAll，将跳过添加注册调用"
        SKIP_REGISTER=true
    fi
    
    # 创建临时文件
    local TEMP_FILE=$(mktemp)
    
    # 处理App.C文件
    local include_added=false
    local register_added=false
    
    while IFS= read -r line || [ -n "$line" ]; do
        echo "$line" >> "$TEMP_FILE"
        
        # 在#include "MooseSyntax.h"后添加#include "base/raccoonApp.h"
        if echo "$line" | grep -q '#include.*"MooseSyntax\.h"' && [ "$SKIP_INCLUDE" = false ]; then
            echo "" >> "$TEMP_FILE"
            echo "// Include RACCOON app" >> "$TEMP_FILE"
            echo '#include "base/raccoonApp.h"' >> "$TEMP_FILE"
            include_added=true
            print_info "已添加raccoonApp.h包含语句"
        fi
        
        # 在ModulesApp::registerAllObjects<*App>后添加raccoonApp::registerAll
        if echo "$line" | grep -q "ModulesApp::registerAllObjects<.*App>" && [ "$SKIP_REGISTER" = false ]; then
            echo "  " >> "$TEMP_FILE"
            echo "  // Register RACCOON" >> "$TEMP_FILE"
            echo "  raccoonApp::registerAll(f, af, syntax);" >> "$TEMP_FILE"
            register_added=true
            print_info "已添加RACCOON注册调用"
        fi
        
    done < "$APP_FILE"
    
    # 检查是否成功添加
    if [ "$SKIP_INCLUDE" = false ] && [ "$include_added" = false ]; then
        print_error "未找到'#include \"MooseSyntax.h\"'行，无法添加raccoonApp.h包含语句"
        print_info "请手动添加: #include \"base/raccoonApp.h\""
    fi
    
    if [ "$SKIP_REGISTER" = false ] && [ "$register_added" = false ]; then
        print_error "未找到'ModulesApp::registerAllObjects'行，无法添加RACCOON注册调用"
        print_info "请手动添加: raccoonApp::registerAll(f, af, syntax);"
    fi
    
    # 替换原文件
    mv "$TEMP_FILE" "$APP_FILE"
    print_success "App.C文件修改完成！"
    
    return 0
}

# 主程序开始
print_info "开始RACCOON集成配置..."

# 修改Makefile
modify_makefile
MAKEFILE_SUCCESS=$?

# 修改App.C文件
modify_app_file
APP_FILE_SUCCESS=$?

# 显示最终结果
echo ""
print_info "============================================"
print_info "配置完成总结："

if [ $MAKEFILE_SUCCESS -eq 0 ]; then
    print_success "✅ Makefile配置成功"
else
    print_error "❌ Makefile配置失败"
fi

if [ $APP_FILE_SUCCESS -eq 0 ]; then
    print_success "✅ App.C文件配置成功"  
else
    print_error "❌ App.C文件配置失败"
fi

# 验证最终结果
echo ""
print_info "验证修改结果:"

# 验证Makefile
if grep -q "RACCOON_DIR" "Makefile" 2>/dev/null; then
    print_success "✅ Makefile中RACCOON_DIR配置已存在"
else
    print_error "❌ Makefile中RACCOON_DIR配置缺失"
fi

if grep -q "RACCOON.*:=.*yes" "Makefile" 2>/dev/null; then
    print_success "✅ Makefile中RACCOON依赖配置已存在"
else
    print_error "❌ Makefile中RACCOON依赖配置缺失"
fi

# 验证App.C文件
APP_FILES=($(find src/base -name "*App.C" 2>/dev/null || true))
if [ ${#APP_FILES[@]} -gt 0 ]; then
    local APP_FILE="${APP_FILES[0]}"
    
    if grep -q "#include.*raccoonApp\.h" "$APP_FILE"; then
        print_success "✅ App.C中raccoonApp.h包含语句已存在"
    else
        print_error "❌ App.C中raccoonApp.h包含语句缺失"
    fi
    
    if grep -q "raccoonApp::registerAll" "$APP_FILE"; then
        print_success "✅ App.C中RACCOON注册调用已存在"
    else
        print_error "❌ App.C中RACCOON注册调用缺失"
    fi
fi

echo ""
print_info "备份文件已创建，如需撤销修改，请查看相应的.backup文件"

if [ $MAKEFILE_SUCCESS -eq 0 ] && [ $APP_FILE_SUCCESS -eq 0 ]; then
    print_success "🎉 RACCOON集成配置完成！现在可以编译支持RACCOON的应用程序了。"
    echo ""
    print_info "下一步："
    echo "  1. 编译应用: make clean && make -j4"
    echo "  2. 验证集成: ./your-app-opt --dump | grep -i raccoon"
else
    print_warning "⚠️  部分配置可能需要手动完成，请查看上述错误信息。"
fi