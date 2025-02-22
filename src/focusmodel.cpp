/**
harbour-advanced-camera C++ Camera Models
Copyright (C) 2019 Adam Pigg (adam@piggz.co.uk)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
**/
#include "focusmodel.h"

FocusModel::FocusModel()
{
}

QHash<int, QByteArray> FocusModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[FocusName] = "name";
    roles[FocusValue] = "value";
    return roles;
}

int FocusModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_focusModes.count();
}

QVariant FocusModel::data(const QModelIndex &index, int role) const
{
    QVariant v;

    if (!index.isValid() || index.row() > rowCount(index) || index.row() < 0) {
        return v;
    }

    if (role == FocusName) {
        v = m_focusModes.values().at(index.row());
    } else if (role == FocusValue) {
        v = m_focusModes.keys().at(index.row());
    }

    return v;
}

void FocusModel::setCamera(QObject *camera)
{
    QCamera *cam = camera->property("mediaObject").value<QCamera *>();
    if (m_camera != cam) {
        m_camera = cam;

        beginResetModel();
        for (int c = (int)QCameraFocus::ManualFocus; c <= (int)QCameraFocus::MacroFocus; c++) {
            if (m_camera->focus()->isFocusModeSupported((QCameraFocus::FocusMode)c)
                    && focusName((QCameraFocus::FocusMode)c) != tr("Unknown")) {
                qDebug() << "Found support for" << (QCameraFocus::FocusMode)c;
                m_focusModes[(QCameraFocus::FocusMode)c] = focusName((QCameraFocus::FocusMode)c);
            }
        }
        //Add manual mode even if not supported as we simulate it
        if (!m_focusModes.contains(QCameraFocus::ManualFocus)) {
            m_focusModes[QCameraFocus::ManualFocus] = focusName(QCameraFocus::ManualFocus);
        }
        endResetModel();
        emit rowCountChanged();

        if (m_focusModes.size() == 0) {
            qDebug() << "No focus modes found";
        }
    }
}

QString FocusModel::focusName(QCameraFocus::FocusMode focus) const
{
    QString name;
    qDebug() << "Checking focus name: " << focus;

    switch (focus) {
    case QCameraFocus::ManualFocus:
        name = tr("Manual");
        break;
    case QCameraFocus::HyperfocalFocus:
        name = tr("Hyperfocal");
        break;
    case QCameraFocus::InfinityFocus:
        name = tr("Infinity");
        break;
    case QCameraFocus::AutoFocus:
        name = tr("Auto");
        break;
    case QCameraFocus::ContinuousFocus:
        name = tr("Continuous");
        break;
    case QCameraFocus::MacroFocus:
        name = tr("Macro");
        break;
    default:
        name = tr("Unknown");
        break;
    }
    return name;
}
