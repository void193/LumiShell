#include "changebatcher.hpp"

namespace lumishell::settings {

ChangeBatcher::ChangeBatcher(QObject* parent)
    : QObject(parent)
    , m_dirty(false) {}

void ChangeBatcher::dirty() {
    if (m_dirty)
        return;

    m_dirty = true;
    QMetaObject::invokeMethod(this, &ChangeBatcher::flush, Qt::QueuedConnection);
}

void ChangeBatcher::flush() {
    if (!m_dirty)
        return;

    m_dirty = false;
    emit dirtied();
}

} // namespace lumishell::settings
