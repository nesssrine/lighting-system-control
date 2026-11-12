from setuptools import setup

package_name = 'lsc_virtual'
setup(
    name=package_name,
    version='1.0.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        ('share/' + package_name + '/launch', ['launch/lsc_launch.py', 'launch/lsc_demo_launch.py']),
        ('share/' + package_name + '/worlds', ['worlds/lsc_demo.wbt', 'worlds/lsc_trajet_complet.wbt', 'worlds/lsc_jour_tunnel.wbt', 'worlds/lsc_nuit.wbt']),
        ('share/' + package_name + '/resource', ['resource/lsc_car.urdf', 'resource/lsc_ambiance.urdf', 'resource/lsc_car_demo.urdf', 'resource/lsc_hud.urdf']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Amina Borcheni',
    maintainer_email='amina.borcheni@enetcom.tn',
    description='Vehicule virtuel Webots pilote par le calculateur LSC',
    license='Apache-2.0',
    entry_points={'console_scripts': [
        'dashboard = lsc_virtual.dashboard:main',
        'plot_log = lsc_virtual.plot_log:main',
        'lane_follower = lsc_virtual.lane_follower:main',
        'scenario = lsc_virtual.scenario:main',
        'demo = lsc_virtual.demo:main',
    ]},
)
