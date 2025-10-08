#!/bin/bash
# select-project.sh - Reusable project selection helper for tfgrid-ai-agent
# Provides numbered list with smart selection (number, name, or default)

# Function to select a project from VM
# Usage: select_project_from_vm "VM_IP"
# Returns: Selected project name in PROJECT_NAME variable
select_project_from_vm() {
    local vm_ip="$1"
    
    if [ -z "$vm_ip" ]; then
        echo "❌ Error: VM IP is required"
        return 1
    fi
    
    # Get list of projects via SSH
    local projects_list
    projects_list=$(ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@"$vm_ip" \
        "cd /opt/ai-agent && make list" 2>/dev/null | grep "📁" | sed 's/.*📁 //')
    
    if [ -z "$projects_list" ]; then
        echo "❌ No projects found"
        echo ""
        echo "Create one with: make create"
        return 1
    fi
    
    # Convert to array
    mapfile -t PROJECTS <<< "$projects_list"
    
    # Show numbered list
    echo "Available projects:"
    for i in "${!PROJECTS[@]}"; do
        local num=$((i + 1))
        if [ $num -eq 1 ]; then
            echo "  $num. ${PROJECTS[$i]} [default]"
        else
            echo "  $num. ${PROJECTS[$i]}"
        fi
    done
    echo ""
    
    # Prompt for selection
    local selection
    if [ ${#PROJECTS[@]} -eq 1 ]; then
        read -p "Select project [${PROJECTS[0]}]: " selection
    else
        read -p "Select project (1-${#PROJECTS[@]}) or name [1]: " selection
    fi
    echo ""
    
    # Handle selection
    if [ -z "$selection" ]; then
        PROJECT_NAME="${PROJECTS[0]}"
        return 0
    elif [[ "$selection" =~ ^[0-9]+$ ]]; then
        local idx=$((selection - 1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#PROJECTS[@]} ]; then
            PROJECT_NAME="${PROJECTS[$idx]}"
            return 0
        else
            echo "❌ Invalid selection: $selection"
            return 1
        fi
    else
        # Check if project name exists in list
        local found=false
        for project in "${PROJECTS[@]}"; do
            if [ "$project" = "$selection" ]; then
                found=true
                break
            fi
        done
        
        if [ "$found" = true ]; then
            PROJECT_NAME="$selection"
            return 0
        else
            echo "❌ Project not found: $selection"
            return 1
        fi
    fi
}
