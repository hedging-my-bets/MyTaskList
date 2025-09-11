import React from 'react';
import { View, StyleSheet, Image } from 'react-native';
import { ThemedText } from './ThemedText';
import { StageForm } from '../types';

interface PetDisplayProps {
  stage: StageForm;
  size?: number;
  showName?: boolean;
}

/**
 * Display the current pet form with image and name
 */
export function PetDisplay({ stage, size = 120, showName = true }: PetDisplayProps) {
  
  // For now using placeholder images - these will be replaced with actual pet assets
  const getPlaceholderImage = (stageIndex: number) => {
    // Return a color based on stage for visual distinction
    const colors = [
      '#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#F44336',
      '#00BCD4', '#8BC34A', '#FFC107', '#E91E63', '#607D8B',
      '#795548', '#FF5722', '#3F51B5', '#009688', '#CDDC39',
      '#673AB7', '#FF9800', '#9E9E9E', '#FF6F00', '#FFD700'
    ];
    
    return colors[stageIndex % colors.length];
  };

  return (
    <View style={styles.container}>
      {/* Placeholder pet image */}
      <View 
        style={[
          styles.petImage,
          { 
            width: size, 
            height: size,
            backgroundColor: getPlaceholderImage(stage.i),
          }
        ]}
      >
        <ThemedText style={[styles.petEmoji, { fontSize: size * 0.4 }]}>
          {getPetEmoji(stage.name)}
        </ThemedText>
      </View>
      
      {showName && (
        <ThemedText style={styles.petName}>
          {stage.name}
        </ThemedText>
      )}
    </View>
  );
}

/**
 * Get emoji representation for each pet stage
 */
function getPetEmoji(stageName: string): string {
  const emojiMap: { [key: string]: string } = {
    'Tadpole': '🐸',
    'Minnow': '🐟',
    'Frog': '🐸',
    'Hermit Crab': '🦀',
    'Starfish': '⭐',
    'Jellyfish': '🪼',
    'Squid': '🦑',
    'Seahorse': '🐴',
    'Dolphin': '🐬',
    'Shark': '🦈',
    'Otter': '🦦',
    'Fox': '🦊',
    'Lynx': '🐱',
    'Wolf': '🐺',
    'Bear': '🐻',
    'Bison': '🦬',
    'Elephant': '🐘',
    'Rhino': '🦏',
    'Lion': '🦁',
    'Floating God': '✨'
  };
  
  return emojiMap[stageName] || '🐾';
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginVertical: 10,
  },
  petImage: {
    borderRadius: 60,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: '#E0E0E0',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  petEmoji: {
    fontWeight: 'bold',
  },
  petName: {
    fontSize: 18,
    fontWeight: '600',
    marginTop: 8,
    textAlign: 'center',
  },
});