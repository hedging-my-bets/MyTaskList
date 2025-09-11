import React, { useState, useEffect, useCallback } from 'react';
import { View, StyleSheet, ScrollView, RefreshControl, TouchableOpacity, Alert } from 'react-native';
import { ThemedText } from '../components/ThemedText';
import { ThemedView } from '../components/ThemedView';
import { PetDisplay } from '../components/PetDisplay';
import { ProgressBar } from '../components/ProgressBar';
import { TaskListItem } from '../components/TaskListItem';
import { TaskService } from '../services/TaskService';
import { DailyCloseoutService } from '../services/DailyCloseoutService';
import { TaskItem, PetState } from '../types';
import { getCurrentDayKey } from '../utils/dateUtils';
import { PetEngine } from '../engine/PetEngine';
import { STAGE_CONFIG } from '../data/stageConfig';

export function TodayScreen() {
  const [tasks, setTasks] = useState<TaskItem[]>([]);
  const [petState, setPetState] = useState<PetState | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = useCallback(async () => {
    try {
      // Check for daily closeout first
      await DailyCloseoutService.checkAndRunCloseout();
      
      // Load today's tasks
      const todayKey = getCurrentDayKey();
      const todayTasks = await TaskService.getTasksForDay(todayKey);
      setTasks(todayTasks);
      
      // Load pet state
      const currentPetState = await TaskService.getPetState();
      setPetState(currentPetState);
      
    } catch (error) {
      console.error('Error loading data:', error);
      Alert.alert('Error', 'Failed to load data. Please try again.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleRefresh = useCallback(() => {
    setRefreshing(true);
    loadData();
  }, [loadData]);

  const handleCompleteTask = useCallback(async (taskId: string) => {
    try {
      await TaskService.completeTask(taskId);
      await loadData(); // Reload to show updated state
    } catch (error) {
      console.error('Error completing task:', error);
      Alert.alert('Error', 'Failed to complete task. Please try again.');
    }
  }, [loadData]);

  const handleSnoozeTask = useCallback(async (taskId: string) => {
    try {
      await TaskService.snoozeTask(taskId, 15); // 15 minute snooze
      await loadData(); // Reload to show updated state
    } catch (error) {
      console.error('Error snoozing task:', error);
      Alert.alert('Error', 'Failed to snooze task. Please try again.');
    }
  }, [loadData]);

  const handleAddTask = () => {
    // TODO: Navigate to add task screen
    Alert.alert('Add Task', 'Add task functionality coming soon!');
  };

  if (loading || !petState) {
    return (
      <ThemedView style={styles.container}>
        <ThemedText style={styles.loadingText}>Loading...</ThemedText>
      </ThemedView>
    );
  }

  const currentStage = STAGE_CONFIG.stages[petState.stageIndex];
  const { progressRatio } = PetEngine.getCurrentStage(petState, STAGE_CONFIG);
  const completedTasks = tasks.filter(t => t.isCompleted).length;
  const totalTasks = tasks.length;
  const nextTask = tasks.find(t => !t.isCompleted);

  return (
    <ThemedView style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
      >
        {/* Pet Display */}
        <View style={styles.petSection}>
          <PetDisplay 
            stage={currentStage}
            size={140}
            showName={true}
          />
          
          <ProgressBar
            current={petState.stageXP}
            max={currentStage.threshold}
            stageName={currentStage.name}
            width={280}
            height={24}
            showText={true}
          />
        </View>

        {/* Today's Summary */}
        <View style={styles.summarySection}>
          <ThemedText style={styles.summaryTitle}>Today's Progress</ThemedText>
          
          <View style={styles.statsRow}>
            <View style={styles.statItem}>
              <ThemedText style={styles.statNumber}>{completedTasks}</ThemedText>
              <ThemedText style={styles.statLabel}>Completed</ThemedText>
            </View>
            
            <View style={styles.statItem}>
              <ThemedText style={styles.statNumber}>{totalTasks - completedTasks}</ThemedText>
              <ThemedText style={styles.statLabel}>Remaining</ThemedText>
            </View>
            
            <View style={styles.statItem}>
              <ThemedText style={styles.statNumber}>
                {totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0}%
              </ThemedText>
              <ThemedText style={styles.statLabel}>Complete</ThemedText>
            </View>
          </View>
        </View>

        {/* Next Task */}
        {nextTask && (
          <View style={styles.nextTaskSection}>
            <ThemedText style={styles.nextTaskTitle}>Up Next</ThemedText>
            <TaskListItem
              task={nextTask}
              onComplete={handleCompleteTask}
              onSnooze={handleSnoozeTask}
            />
          </View>
        )}

        {/* Task List */}
        <View style={styles.taskListSection}>
          <View style={styles.taskListHeader}>
            <ThemedText style={styles.taskListTitle}>All Tasks</ThemedText>
            <TouchableOpacity 
              style={styles.addButton}
              onPress={handleAddTask}
            >
              <ThemedText style={styles.addButtonText}>+ Add</ThemedText>
            </TouchableOpacity>
          </View>

          {tasks.length === 0 ? (
            <View style={styles.emptyState}>
              <ThemedText style={styles.emptyStateText}>
                No tasks for today.{'\n'}Add some tasks to get started!
              </ThemedText>
            </View>
          ) : (
            tasks.map(task => (
              <TaskListItem
                key={task.id}
                task={task}
                onComplete={handleCompleteTask}
                onSnooze={handleSnoozeTask}
              />
            ))
          )}
        </View>

        {/* Bottom padding for scroll */}
        <View style={styles.bottomPadding} />
      </ScrollView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  loadingText: {
    textAlign: 'center',
    fontSize: 18,
    marginTop: 50,
  },
  petSection: {
    alignItems: 'center',
    paddingVertical: 20,
    backgroundColor: '#F5F5F5',
    marginBottom: 16,
  },
  summarySection: {
    paddingHorizontal: 16,
    marginBottom: 16,
  },
  summaryTitle: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 12,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2196F3',
  },
  statLabel: {
    fontSize: 14,
    color: '#666666',
    marginTop: 2,
  },
  nextTaskSection: {
    paddingHorizontal: 16,
    marginBottom: 16,
  },
  nextTaskTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 8,
  },
  taskListSection: {
    flex: 1,
  },
  taskListHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    marginBottom: 8,
  },
  taskListTitle: {
    fontSize: 18,
    fontWeight: '600',
  },
  addButton: {
    backgroundColor: '#2196F3',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  addButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 40,
    paddingHorizontal: 16,
  },
  emptyStateText: {
    fontSize: 16,
    color: '#666666',
    textAlign: 'center',
    lineHeight: 24,
  },
  bottomPadding: {
    height: 40,
  },
});