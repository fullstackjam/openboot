#!/usr/bin/env bash
# Rollback module - restore backed up files (bash 3.2 compatible)

BACKUP_DIR="$HOME/.openboot/backup"

rollback_list() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "No backups found at $BACKUP_DIR"
        return 1
    fi
    
    local count=0
    echo "Available backups in $BACKUP_DIR:"
    echo ""
    printf "%-30s %-20s %s\n" "FILE" "DATE" "SIZE"
    printf "%s\n" "--------------------------------------------------------------"
    
    while IFS= read -r backup; do
        [[ -z "$backup" ]] && continue
        
        local bname
        bname=$(basename "$backup")
        
        local original_name="${bname%.bak.*}"
        local timestamp="${bname##*.bak.}"
        
        local date_str
        date_str=$(date -r "$timestamp" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "unknown")
        
        local size
        size=$(ls -lh "$backup" | awk '{print $5}')
        
        printf "%-30s %-20s %s\n" "$original_name" "$date_str" "$size"
        ((count++))
    done < <(find "$BACKUP_DIR" -name "*.bak.*" -type f 2>/dev/null | sort)
    
    echo ""
    echo "Total: $count backup(s)"
    
    [[ $count -eq 0 ]] && return 1
    return 0
}

rollback_restore() {
    local target="$1"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "No backups found at $BACKUP_DIR"
        return 1
    fi
    
    if [[ -z "$target" ]]; then
        rollback_restore_all
        return $?
    fi
    
    local latest_backup
    latest_backup=$(find "$BACKUP_DIR" -name "${target}.bak.*" -type f 2>/dev/null | sort -t. -k3 -rn | head -1)
    
    if [[ -z "$latest_backup" ]]; then
        echo "No backup found for: $target"
        return 1
    fi
    
    local dest="$HOME/$target"
    
    [[ -L "$dest" ]] && rm "$dest"
    [[ -f "$dest" ]] && rm "$dest"

    cp "$latest_backup" "$dest" || {
        echo "Failed to restore $target"
        return 1
    }
    
    echo "✓ Restored: $target"
}

rollback_restore_all() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "No backups found"
        return 1
    fi
    
    local unique_files
    unique_files=$(find "$BACKUP_DIR" -name "*.bak.*" -type f 2>/dev/null | \
        xargs -I{} basename {} | sed 's/\.bak\.[0-9]*$//' | sort -u)
    
    if [[ -z "$unique_files" ]]; then
        echo "No backups found"
        return 1
    fi
    
    echo "Files to restore:"
    echo "$unique_files" | while read -r file; do
        echo "  - $file"
    done
    echo ""
    
    local file_count
    file_count=$(echo "$unique_files" | wc -l | tr -d ' ')
    
    read -p "Restore all ${file_count} file(s)? [y/N] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled"
        return 0
    fi
    
    local restored=0
    local failed=0
    
    echo "$unique_files" | while read -r file; do
        [[ -z "$file" ]] && continue
        
        local latest_backup
        latest_backup=$(find "$BACKUP_DIR" -name "${file}.bak.*" -type f 2>/dev/null | sort -t. -k3 -rn | head -1)
        
        local dest="$HOME/$file"
        
        [[ -L "$dest" ]] && rm "$dest"
        [[ -f "$dest" ]] && rm "$dest"

        if cp "$latest_backup" "$dest"; then
            echo "✓ Restored: $file"
        else
            echo "✗ Failed: $file"
        fi
    done
    
    echo ""
    echo "Rollback complete"
}

rollback_interactive() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "No backups found at $BACKUP_DIR"
        return 1
    fi
    
    local file_list
    file_list=$(find "$BACKUP_DIR" -name "*.bak.*" -type f 2>/dev/null | \
        xargs -I{} basename {} | sed 's/\.bak\.[0-9]*$//' | sort -u)
    
    if [[ -z "$file_list" ]]; then
        echo "No backups found"
        return 1
    fi
    
    if command -v gum &>/dev/null && [[ -t 0 ]]; then
        echo "Select files to restore (space to select, enter to confirm):"
        local selected
        selected=$(echo "$file_list" | gum choose --no-limit)
        
        if [[ -z "$selected" ]]; then
            echo "No files selected"
            return 0
        fi
        
        while IFS= read -r file; do
            rollback_restore "$file"
        done <<< "$selected"
    else
        rollback_restore_all
    fi
}

rollback_clean() {
    local keep="${1:-3}"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "No backups to clean"
        return 0
    fi
    
    local unique_files
    unique_files=$(find "$BACKUP_DIR" -name "*.bak.*" -type f 2>/dev/null | \
        xargs -I{} basename {} | sed 's/\.bak\.[0-9]*$//' | sort -u)
    
    local removed=0
    
    echo "$unique_files" | while read -r file; do
        [[ -z "$file" ]] && continue
        
        local backups
        backups=$(find "$BACKUP_DIR" -name "${file}.bak.*" -type f 2>/dev/null | sort -t. -k3 -rn)
        
        local count=0
        echo "$backups" | while read -r backup; do
            [[ -z "$backup" ]] && continue
            ((count++))
            
            if [[ $count -gt $keep ]]; then
                rm "$backup"
                echo "Removed: $(basename "$backup")"
            fi
        done
    done
    
    echo "Cleanup complete, keeping latest $keep per file"
}

rollback_status() {
    echo "=== OpenBoot Rollback Status ==="
    echo ""
    
    if [[ -d "$BACKUP_DIR" ]]; then
        local count
        count=$(find "$BACKUP_DIR" -name "*.bak.*" -type f 2>/dev/null | wc -l | tr -d ' ')
        local size
        size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        
        echo "Backup directory: $BACKUP_DIR"
        echo "Total backups: $count"
        echo "Total size: $size"
    else
        echo "No backups found"
    fi
}
