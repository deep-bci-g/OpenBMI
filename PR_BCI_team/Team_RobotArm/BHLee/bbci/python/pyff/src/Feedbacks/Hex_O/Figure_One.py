"""PolygonStimulus and helper functions"""
import VisionEgg
import VisionEgg.ParameterTypes as ve_types
from VisionEgg.Core import *
from math import *
import OpenGL.GL as gl
import numpy as np
import pylab as p
# used to display text
import OpenGL.GLUT as glut
import pylab as py
from VisionEgg.Text import *


class Figure_One(Stimulus):             
    """Displays symmetric figure with one letter in"""
    #defines the parameters to be used by figure
    parameters_and_defaults = {
        'time_passed':(0.0,
            ve_types.Real),
        'color_on':((1.0,1.0,1.0),
            ve_types.AnyOf(ve_types.Sequence3(ve_types.Real))),
        'color_off':((0.0,0.0,0.0),
            ve_types.AnyOf(ve_types.Sequence3(ve_types.Real))),
        'center_position':(( 320.0, 240.0 ),
            ve_types.AnyOf(ve_types.Sequence2(ve_types.Real))),
        'radius_size':(64.0,
            ve_types.Real),
        'corners_number':(6,
            ve_types.Integer),
        'frequency_used':(3.0,
            ve_types.Real),
        'font_size':(18,
               ve_types.Real), 
        'letters_to_use':('Abcde',
            ve_types.String), 
        'figure_number':(0,
            ve_types.Integer),
        'animate': (0,
            ve_types.Real),
        'screen_center':(( 320.0, 240.0 ),
            ve_types.AnyOf(ve_types.Sequence2(ve_types.Real)))}
               
    def __init__(self, **kw):
        """initializes everything"""
        VisionEgg.Core.Stimulus.__init__(self,**kw)
        corners = self.parameters.corners_number
        radius = self.parameters.radius_size
        offset = 360 / (corners * 2) # If there is two parallell sides, we want them horizontal
        self.many_letters_font_size = 50
        self.color_letters_off = self.parameters.color_on
        #initialize letters  
        distance_between = 15
        
    def draw(self):
        """draws all to the screen"""
        p = self.parameters     
        corners = self.parameters.corners_number
        radius = self.parameters.radius_size
        offset = 360 / (corners * 2) # If there is two parallell sides, we want them horizontal
        gl.glPushMatrix()
        gl.glLoadIdentity()
        corners = self.parameters.corners_number
        radius = self.parameters.radius_size   
        if int(p.time_passed * p.frequency_used * 2.0) % 2: 
            self.colors = p.color_on
            self.colors_font = p.color_off
        else:
            self.colors = p.color_off
            self.colors_font = p.color_on
        self.center = p.center_position
        if p.animate > 0.0:
            self.animate_figure()                
        else:    
            self.center = p.center_position        
        #gives the graphical card colors and draws it to the screen
        gl.glColor3f(self.colors[0], self.colors[1], self.colors[2])
        gl.glTranslate(self.center[0], self.center[1], 0.0)
        angles = [radians(v) for v in range(offset, 360 + offset , 360 / corners)]
        self.points = [(radius * sin(v), radius * cos(v)) for v in angles ]           
        gl.glBegin(gl.GL_POLYGON)
        for (x, y) in self.points: 
            gl.glVertex3f(x, y, 0.0)        
        gl.glEnd()
        gl.glPolygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL)
        gl.glPopMatrix()
        gl.glColor3f(self.colors_font[0], self.colors_font[1], self.colors_font[2])
        gl.glPushMatrix()
        gl.glRasterPos2f(self.center[0] - 0.25 * p.font_size, self.center[1] - 0.25 * p.font_size)
        if p.font_size <= 10:
            glut.glutBitmapCharacter(glut.GLUT_BITMAP_HELVETICA_10, ord(p.letters_to_use[p.figure_number]))            
        elif p.font_size <= 12:
            glut.glutBitmapCharacter(glut.GLUT_BITMAP_HELVETICA_12, ord(p.letters_to_use[p.figure_number])) 
        elif p.font_size <= 13:
            glut.glutBitmapCharacter(glut.GLUT_BITMAP_8_BY_13, ord(p.letters_to_use[p.figure_number]))            
        elif p.font_size <= 15:
            glut.glutBitmapCharacter(glut.GLUT_BITMAP_9_BY_15, ord(p.letters_to_use[p.figure_number]))                            
        elif p.font_size <= 18:
            glut.glutBitmapCharacter(glut.GLUT_BITMAP_HELVETICA_18, ord(p.letters_to_use[p.figure_number]))            
        else:
            glut.glutBitmapCharacter(glut.GLUT_BITMAP_TIMES_ROMAN_24, ord(p.letters_to_use[p.figure_number])) 
        gl.glPopMatrix()
        
    def animate_figure(self):
        p = self.parameters
        fraction = 18
        #if it is time to show this figure        
        if p.time_passed > ((p.animate/fraction)*(p.figure_number)):
            self.colors = p.color_on
            self.colors_font = p.color_off
            next_figure = ((p.animate/fraction) * (p.figure_number + 1))
            #if this is time to animate this figure
            if p.time_passed <= next_figure - 0.3 * (p.animate/fraction):
                self.center = p.screen_center
            elif p.time_passed <= next_figure:
                a1 = (p.screen_center[1] - p.center_position[1])
                a2 = (p.screen_center[0] - p.center_position[0])
                my_time = p.time_passed - p.figure_number * (p.animate/fraction)
                if np.abs(a2) < 0.001:
                #if the figure is on the vertical line with the center
                    x = p.screen_center[0]
                    y = p.screen_center[1] + (p.center_position[1]-p.screen_center[1]) * (my_time)/p.animate*6
                else: 
                    a = (a1/a2)
                    b = p.center_position[1] - a * p.center_position[0]
                    x = p.screen_center[0] + (p.center_position[0]-p.screen_center[0]) * (my_time)/p.animate*6 
                    y = a * x + b
                self.center = (x, y)
            else:
                self.center = p.center_position
        else:
            self.colors = (0.5,0.5,0.5)
            self.colors_font = (0.5,0.5,0.5)
            self.center = p.center_position
                
        self.letters_position = self.center
        #self.letters_to_use = self.parameters.letters_to_use
