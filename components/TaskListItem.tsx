import React from 'react';
import { View, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { ThemedText } from './ThemedText';
import { TaskItem } from '../types';
import { formatTime } from '../utils/dateUtils';

interface TaskListItemProps {
  task: TaskItem;
  onComplete: (taskId: string) => void;
  onSnooze: (taskId: string) => void;
  onEdit?: (task: TaskItem) => void;
}

/**
 * Individual task item with swipe actions for Done/Snooze
 */
export function TaskListItem({ task, onComplete, onSnooze, onEdit }: TaskListItemProps) {
  
  const handleComplete = () => {
    if (task.isCompleted) return;
    onComplete(task.id);
  };

  const handleSnooze = () => {
    if (task.isCompleted) return;
    onSnooze(task.id);
  };

  const handleLongPress = () => {
    if (onEdit) {
      onEdit(task);
    }
  };

  const isOverdue = () => {
    if (task.isCompleted) return false;
    const now = new Date();
    const today = now.toLocaleDateString('en-CA');
    if (task.dayKey !== today) return task.dayKey < today;
    
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const taskMinutes = task.scheduledAt.hour * 60 + task.scheduledAt.minute;
    return currentMinutes > taskMinutes + 60; // 1 hour grace period
  };

  const getStatusColor = () => {
    if (task.isCompleted) return '#4CAF50'; // Green
    if (isOverdue()) return '#F44336'; // Red
    if (task.snoozedUntil) return '#FF9800'; // Orange
    return '#2196F3'; // Blue
  };

  return (
    <View style={[styles.container, task.isCompleted && styles.completedContainer]}>
      <View style={styles.content}>
        {/* Status indicator */}
        <View style={[styles.statusDot, { backgroundColor: getStatusColor() }]} />
        
        {/* Task details */}
        <View style={styles.taskInfo}>
          <ThemedText 
            style={[
              styles.title,
              task.isCompleted && styles.completedText
            ]}
            numberOfLines={2}
          >
            {task.title}
          </ThemedText>
          
          <View style={styles.timeRow}>
            <ThemedText style={styles.time}>
              {formatTime(task.scheduledAt.hour, task.scheduledAt.minute)}
            </ThemedText>
            
            {task.snoozedUntil && (
              <ThemedText style={styles.snoozedText}>
                Snoozed
              </ThemedText>
            )}
            
            {isOverdue() && !task.isCompleted && (
              <ThemedText style={styles.overdueText}>
                Overdue
              </ThemedText>
            )}
          </View>
        </View>
        
        {/* Action buttons */}
        {!task.isCompleted && (
          <View style={styles.actions}>
            <TouchableOpacity 
              style={[styles.actionButton, styles.snoozeButton]}
              onPress={handleSnooze}
            >
              <ThemedText style={styles.actionText}>⏰</ThemedText>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={[styles.actionButton, styles.doneButton]}
              onPress={handleComplete}
            >
              <ThemedText style={styles.actionText}>✓</ThemedText>
            </TouchableOpacity>
          </View>
        )}
        
        {task.isCompleted && (
          <View style={styles.completedIndicator}>
            <ThemedText style={styles.completedEmoji}>✅</ThemedText>
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    marginVertical: 4,
    marginHorizontal: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 1,
    },
    shadowOpacity: 0.22,
    shadowRadius: 2.22,
    elevation: 3,
  },
  completedContainer: {
    opacity: 0.7,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 12,
  },
  taskInfo: {
    flex: 1,
  },
  title: {
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 4,
  },
  completedText: {
    textDecorationLine: 'line-through',
    opacity: 0.7,
  },
  timeRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  time: {
    fontSize: 14,
    color: '#666666',
    fontWeight: '500',
  },
  snoozedText: {
    fontSize: 12,
    color: '#FF9800',
    marginLeft: 8,
    fontWeight: '500',
  },
  overdueText: {
    fontSize: 12,
    color: '#F44336',
    marginLeft: 8,
    fontWeight: '600',
  },
  actions: {
    flexDirection: 'row',
  },
  actionButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 8,
  },
  snoozeButton: {
    backgroundColor: '#FF9800',
  },
  doneButton: {
    backgroundColor: '#4CAF50',
  },
  actionText: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  completedIndicator: {
    marginLeft: 8,
  },
  completedEmoji: {
    fontSize: 20,
  },
});