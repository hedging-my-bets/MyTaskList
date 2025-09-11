import React from 'react';
import { View, StyleSheet } from 'react-native';
import { ThemedText } from './ThemedText';

interface ProgressBarProps {
  current: number;
  max: number;
  stageName: string;
  width?: number;
  height?: number;
  showText?: boolean;
}

/**
 * Progress bar showing stageXP/threshold for pet evolution
 */
export function ProgressBar({ 
  current, 
  max, 
  stageName, 
  width = 200, 
  height = 20, 
  showText = true 
}: ProgressBarProps) {
  
  // Handle final stage (max = 0)
  const progressRatio = max > 0 ? Math.min(1, current / max) : 1;
  const progressWidth = width * progressRatio;
  
  return (
    <View style={styles.container}>
      {showText && (
        <ThemedText style={styles.stageText}>
          {stageName} - Stage {current >= 0 ? `${current}` : '0'}/{max > 0 ? max : 'MAX'}
        </ThemedText>
      )}
      
      <View style={[styles.track, { width, height }]}>
        <View 
          style={[
            styles.fill,
            { 
              width: progressWidth,
              height: height - 2,
              backgroundColor: getProgressColor(progressRatio)
            }
          ]}
        />
      </View>
      
      {showText && (
        <ThemedText style={styles.progressText}>
          {Math.round(progressRatio * 100)}%
        </ThemedText>
      )}
    </View>
  );
}

/**
 * Get progress bar color based on completion ratio
 */
function getProgressColor(ratio: number): string {
  if (ratio >= 0.8) return '#4CAF50'; // Green
  if (ratio >= 0.5) return '#FF9800'; // Orange  
  if (ratio >= 0.2) return '#FFC107'; // Yellow
  return '#F44336'; // Red
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginVertical: 8,
  },
  stageText: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
  },
  track: {
    backgroundColor: '#E0E0E0',
    borderRadius: 10,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'flex-start',
    borderWidth: 1,
    borderColor: '#BDBDBD',
  },
  fill: {
    borderRadius: 9,
    margin: 1,
    minWidth: 2, // Ensure some visual feedback even at 0
  },
  progressText: {
    fontSize: 12,
    marginTop: 2,
    opacity: 0.8,
  },
});